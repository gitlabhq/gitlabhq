require 'html/pipeline'
require 'html/pipeline/gitlab'

module EmailsHelper

  # Google Actions
  # https://developers.google.com/gmail/markup/reference/go-to-action
  def email_action(url)
    name = action_title(url)
    if name
      data = {
        "@context" => "http://schema.org",
        "@type" => "EmailMessage",
        "action" => {
          "@type" => "ViewAction",
          "name" => name,
          "url" => url,
          }
        }

      content_tag :script, type: 'application/ld+json' do
        data.to_json.html_safe
      end
    end
  end

  def action_title(url)
    return unless url
    ["merge_requests", "issues", "commit"].each do |action|
      if url.split("/").include?(action)
        return "View #{action.humanize.singularize}"
      end
    end
  end

  def add_email_highlight_css
    Rugments::Themes::Github.render(scope: '.highlight')
  end

  def color_email_diff(diffcontent)
    formatter = Rugments::Formatters::HTML.new(cssclass: 'highlight')
    lexer = Rugments::Lexers::Diff.new
    raw formatter.format(lexer.lex(diffcontent))
  end

  def replace_image_links_with_base64(text, project)
    # Used pipelines in GitLab:
    # GitlabEmailImageFilter - replaces images that have been uploaded as attachments with inline images in emails.
    #
    # see https://gitlab.com/gitlab-org/html-pipeline-gitlab for more filters
    filters = [
      HTML::Pipeline::Gitlab::GitlabEmailImageFilter
    ]

    context = {
      base_url: File.join(Gitlab.config.gitlab.url, project.path_with_namespace, 'uploads'),
      upload_path: File.join(Rails.root, 'public', 'uploads', project.path_with_namespace),
    }

    pipeline = HTML::Pipeline::Gitlab.new(filters).pipeline

    result = pipeline.call(text, context)
    text = result[:output].to_html(save_with: 0)

    text.html_safe
  end
end
