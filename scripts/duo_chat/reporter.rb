#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require 'json'

class Reporter
  GITLAB_COM_API_V4_ENDPOINT = "https://gitlab.com/api/v4"
  QA_EVALUATION_PROJECT_ID = 52020045 # https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation
  AGGREGATED_REPORT_ISSUE_IID = 1 # https://gitlab.com/gitlab-org/ai-powered/ai-framework/qa-evaluation/-/issues/1
  IDENTIFIABLE_NOTE_TAG = 'gitlab-org/ai-powered/ai-framework:duo-chat-qa-evaluation'

  GRADE_TO_EMOJI_MAPPING = {
    correct: ":white_check_mark:",
    incorrect: ":x:",
    unexpected: ":warning:"
  }.freeze

  def run
    if pipeline_running_on_master_branch?
      snippet_web_url = upload_data_as_snippet
      report_issue_url = create_report_issue
      update_aggregation_issue(report_issue_url, snippet_web_url)
    else
      save_report_as_artifact
      post_or_update_report_note
    end
  end

  def markdown_report
    @report ||= <<~MARKDOWN
    <!-- #{IDENTIFIABLE_NOTE_TAG} -->

    ## GitLab Duo Chat QA evaluation

    Report generated for "#{ENV['CI_JOB_NAME']}". This report is generated and refreshed automatically. Do not edit.

    LLMs have been asked to evaluate GitLab Duo Chat's answers.

    :white_check_mark: : LLM evaluated the answer as `CORRECT`.

    :x: : LLM evaluated the answer as `INCORRECT`.

    :warning: : LLM did not evaluate correctly or the evaluation request might have failed.

    ### Summary

    - The total number of evaluations: #{summary_numbers[:total]}

    - The number of evaluations in which all LLMs graded `CORRECT`: #{summary_numbers[:correct]} (#{summary_numbers[:correct_ratio]}%)

      - Note: if an evaluation request failed or its response was not parsable, it was ignored. For example, :white_check_mark: :warning: would count as `CORRECT`.

    - The number of evaluations in which all LLMs graded `INCORRECT`: #{summary_numbers[:incorrect]} (#{summary_numbers[:incorrect_ratio]}%)

      - Note: if an evaluation request failed or its response was not parsable, it was ignored. For example, :x: :warning: would count as `INCORRECT`.

    - The number of evaluations in which LLMs disagreed: #{summary_numbers[:disagreed]} (#{summary_numbers[:disagreed_ratio]}%)


    ### Evaluations

    #{eval_content}


    MARKDOWN

    # Do this to avoid pinging users in notes/issues.
    quote_usernames(@report)
  end

  private

  def quote_usernames(text)
    text.gsub(/(@\w+)/, '`\\1`')
  end

  def pipeline_running_on_master_branch?
    ENV['CI_COMMIT_BRANCH'] == ENV['CI_DEFAULT_BRANCH']
  end

  def utc_timestamp
    @utc_timestamp ||= Time.now.utc
  end

  def upload_data_as_snippet
    filename = "#{utc_timestamp.to_i}.json"
    title = utc_timestamp.to_s
    snippet_content = ::JSON.pretty_generate({
      commit: ENV["CI_COMMIT_SHA"],
      pipeline_url: ENV["CI_PIPELINE_URL"],
      data: report_data
    })

    puts "Creating a snippet #{filename}."
    snippet = qa_evaluation_project_client.create_snippet(
      QA_EVALUATION_PROJECT_ID,
      {
        title: title,
        files: [{ file_path: filename, content: snippet_content }],
        visibility: 'private'
      }
    )

    snippet.web_url
  end

  def create_report_issue
    puts "Creating a report issue."
    issue_title = "Report #{utc_timestamp}"
    new_issue = qa_evaluation_project_client.create_issue(
      QA_EVALUATION_PROJECT_ID, issue_title, { description: markdown_report }
    )

    new_issue.web_url
  end

  def update_aggregation_issue(report_issue_url, snippet_web_url)
    puts "Updating the aggregated report issue."

    new_line = ["\n|"]
    new_line << "#{utc_timestamp} |"
    new_line << "#{summary_numbers[:total]} |"
    new_line << "#{summary_numbers[:correct_ratio]}% |"
    new_line << "#{summary_numbers[:incorrect_ratio]}% |"
    new_line << "#{summary_numbers[:disagreed_ratio]}% |"
    new_line << "#{report_issue_url} |"
    new_line << "#{snippet_web_url} |"
    new_line = new_line.join(' ')

    aggregated_report_issue = qa_evaluation_project_client.issue(QA_EVALUATION_PROJECT_ID, AGGREGATED_REPORT_ISSUE_IID)
    updated_description = aggregated_report_issue.description + new_line
    qa_evaluation_project_client.edit_issue(
      QA_EVALUATION_PROJECT_ID, AGGREGATED_REPORT_ISSUE_IID, { description: updated_description }
    )
  end

  def save_report_as_artifact
    artifact_path = File.join(base_dir, ENV['QA_EVAL_REPORT_FILENAME'])

    puts "Saving #{artifact_path}"
    File.write(artifact_path, markdown_report)
  end

  def post_or_update_report_note
    note = existing_report_note
    if note && note.type != 'DiscussionNote'
      # The latest note has not led to a discussion. Update it.
      gitlab_project_client.edit_merge_request_note(ci_project_id, merge_request_iid, note.id, markdown_report)

      puts "Updated comment."
    else
      # This is the first note or the latest note has been discussed on the MR.
      # Don't update, create new note instead.
      gitlab_project_client.create_merge_request_note(ci_project_id, merge_request_iid, markdown_report)

      puts "Posted comment."
    end
  end

  def existing_report_note
    # Look for an existing note using `IDENTIFIABLE_NOTE_TAG`
    gitlab_project_client
      .merge_request_notes(ci_project_id, merge_request_iid)
      .auto_paginate
      .select { |note| note.body.include? IDENTIFIABLE_NOTE_TAG }
      .max_by { |note| Time.parse(note.created_at) }
  end

  def gitlab_project_client
    @gitlab_project_client ||= Gitlab.client(
      endpoint: GITLAB_COM_API_V4_ENDPOINT,
      private_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
    )
  end

  def qa_evaluation_project_client
    @qa_evaluation_project_client ||= Gitlab.client(
      endpoint: GITLAB_COM_API_V4_ENDPOINT,
      private_token: ENV['CHAT_QA_EVALUATION_PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
    )
  end

  def base_dir
    ENV['CI_PROJECT_DIR'] || "./"
  end

  def merge_request_iid
    ENV['CI_MERGE_REQUEST_IID']
  end

  def ci_project_id
    ENV['CI_PROJECT_ID']
  end

  def report_data
    @report_data ||= Dir[File.join(base_dir, "tmp/duo_chat/qa*.json")]
      .flat_map { |file| JSON.parse(File.read(file)) }
  end

  def eval_content
    report_data
      .sort_by { |a| a["question"] }
      .map do |data|
        <<~MARKDOWN
        <details>

        <summary>

        #{correctness_indicator(data)}

        `"#{data['question']}"`

        (context: `#{data['resource']}`)

        </summary>

        #### Resource

        `#{data['resource']}`

        #### Answer

        #{data['answer']}

        #### LLM Evaluation

        Tools used: #{data['tools_used']}

        #{evalutions(data)}


        </details>

        MARKDOWN
      end
      .join
  end

  def summary_numbers
    @graded_evaluations ||= report_data
        .map { |data| data["evaluations"].map { |eval| parse_grade(eval) } }
        .reject { |grades| !(grades.include? :correct) && !(grades.include? :incorrect) }

    total = @graded_evaluations.size
    correct = @graded_evaluations.count { |grades| !(grades.include? :incorrect) }
    incorrect = @graded_evaluations.count { |grades| !(grades.include? :correct) }
    disagreed = @graded_evaluations.count { |grades| (grades.include? :correct) && (grades.include? :incorrect) }

    {
      total: total,
      correct: correct,
      correct_ratio: (correct.to_f / total * 100).round(1),
      incorrect: incorrect,
      incorrect_ratio: (incorrect.to_f / total * 100).round(1),
      disagreed: disagreed,
      disagreed_ratio: (disagreed.to_f / total * 100).round(1)
    }
  end

  def parse_grade(eval)
    return :correct if eval["response"].match?(/Grade: CORRECT/i)
    return :incorrect if eval["response"].match?(/Grade: INCORRECT/i)

    # If the LLM's evaluation includes neither CORRECT nor CORRECT, flag it.
    :unexpected
  end

  def correctness_indicator(data)
    data["evaluations"].map { |eval| parse_grade(eval) }.map { |grade| GRADE_TO_EMOJI_MAPPING[grade] }.join(' ')
  end

  def evalutions(data)
    rows = data["evaluations"].map do |eval|
      grade = parse_grade(eval)

      <<~MARKDOWN
      <tr>
        <td>#{eval['model']}</td>
        <td>
          #{GRADE_TO_EMOJI_MAPPING[grade]}
        </td>
        <td>
          #{eval['response']}
        </td
      </tr>

      MARKDOWN
    end
    .join

    <<~MARKDOWN
    <table>
      <tr>
        <td>Model</td>
        <td>Grade</td>
        <td>Details</td>
      </tr>
      #{rows}
    </table>
    MARKDOWN
  end
end

Reporter.new.run if $PROGRAM_NAME == __FILE__
