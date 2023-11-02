#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'json'

class Reporter
  IDENTIFIABLE_NOTE_TAG = 'gitlab-org/ai-powered/ai-framework:duo-chat-qa-evaluation-'

  GRADE_TO_EMOJI_MAPPING = {
    correct: ":white_check_mark:",
    incorrect: ":x:",
    unexpected: ":warning:"
  }.freeze

  def run
    merge_request_iid = ENV['CI_MERGE_REQUEST_IID']
    ci_project_id = ENV['CI_PROJECT_ID']

    puts "Saving #{artifact_path}"
    File.write(artifact_path, report_note)

    # Look for an existing note
    report_notes = com_gitlab_client
      .merge_request_notes(ci_project_id, merge_request_iid)
      .auto_paginate
      .select do |note|
        note.body.include? note_identifier_tag
      end

    note = report_notes.max_by { |note| Time.parse(note.created_at) }

    if note && note.type != 'DiscussionNote'
      # The latest note has not led to a discussion. Update it.
      com_gitlab_client.edit_merge_request_note(ci_project_id, merge_request_iid, note.id, report_note)

      puts "Updated comment."
    else
      # This is the first note or the latest note has been discussed on the MR.
      # Don't update, create new note instead.
      com_gitlab_client.create_merge_request_note(ci_project_id, merge_request_iid, report_note)

      puts "Posted comment."
    end
  end

  private

  def report_filename
    "#{ENV['DUO_RSPEC']}.md"
  end

  def artifact_path
    File.join(ENV['CI_PROJECT_DIR'], report_filename)
  end

  def note_identifier_tag
    "#{IDENTIFIABLE_NOTE_TAG}#{ENV['DUO_RSPEC']}"
  end

  def com_gitlab_client
    @com_gitlab_client ||= Gitlab.client(
      endpoint: "https://gitlab.com/api/v4",
      private_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
    )
  end

  def report_note
    report = <<~MARKDOWN
    <!-- #{note_identifier_tag} -->

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

    - The number of evaluations in which LLMs disagreed:  #{summary_numbers[:disagreed]} (#{summary_numbers[:disagreed_ratio]}%)


    ### Evaluations

    #{eval_content}


    MARKDOWN

    if report.length > 1000000
      return <<~MARKDOWN
      <!-- #{note_identifier_tag} -->

      ## GitLab Duo Chat QA evaluation

      Report generated for "#{ENV['CI_JOB_NAME']}". This report is generated and refreshed automatically. Do not edit.

      **:warning: the evaluation report is too long (> `1000000`) and cannot be posted as a note.**

      Please check out the artifact for the CI job "#{ENV['CI_JOB_NAME']}":

      https://gitlab.com/gitlab-org/gitlab/-/jobs/#{ENV['CI_JOB_ID']}/artifacts/file/#{report_filename}

      MARKDOWN
    end

    report
  end

  def report_data
    @report_data ||= Dir[File.join(ENV['CI_PROJECT_DIR'], "tmp/duo_chat/qa*.json")]
      .map { |file| JSON.parse(File.read(file)) }
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

        #{evalutions(data)}


        </details>

        MARKDOWN
      end
      .join
  end

  def summary_numbers
    @graded_evaluations ||= report_data.map { |data| data["evaluations"].map { |eval| parse_grade(eval) } }

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

Reporter.new.run
