# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :authenticate_user!

  layout 'help'

  # Taken from Jekyll
  # https://github.com/jekyll/jekyll/blob/3.5-stable/lib/jekyll/document.rb#L13
  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze

  def index
    # Remove YAML frontmatter so that it doesn't look weird
    @help_index = File.read(Rails.root.join('doc', 'README.md')).sub(YAML_FRONT_MATTER_REGEXP, '')

    # Prefix Markdown links with `help/` unless they are external links.
    # '//' not necessarily part of URL, e.g., mailto:mail@example.com
    # See https://rubular.com/r/DFHZl5w8d3bpzV
    @help_index.gsub!(%r{(?<delim>\]\()(?!\w+:)(?!/)(?<link>[^\)\(]+\))}) do
      "#{$~[:delim]}#{Gitlab.config.gitlab.relative_url_root}/help/#{$~[:link]}"
    end
  end

  def show
    @path = Rack::Utils.clean_path_info(path_params[:path])

    respond_to do |format|
      format.any(:markdown, :md, :html) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', "#{@path}.md")

        if File.exist?(path)
          # Remove YAML frontmatter so that it doesn't look weird
          @markdown = File.read(path).gsub(YAML_FRONT_MATTER_REGEXP, '')

          render 'show.html.haml'
        else
          # Force template to Haml
          render 'errors/not_found.html.haml', layout: 'errors', status: :not_found
        end
      end

      # Allow access to specific media files in the doc folder
      format.any(:png, :gif, :jpeg, :mp4, :mp3) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', "#{@path}.#{params[:format]}")

        if File.exist?(path)
          send_file(path, disposition: 'inline')
        else
          head :not_found
        end
      end

      # Any other format we don't recognize, just respond 404
      format.any { head :not_found }
    end
  end

  def shortcuts
  end

  def instance_configuration
    @instance_configuration = InstanceConfiguration.new
  end

  def ui
    @user = User.new(id: 0, name: 'John Doe', username: '@johndoe')
  end

  private

  def path_params
    params.require(:path)

    params
  end
end
