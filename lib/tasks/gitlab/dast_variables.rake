# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :dast_variables do
    desc 'GitLab | DAST variables | Generate docs'
    task compile_docs: [:environment] do
      require_relative '../../../tooling/dast_variables/docs/renderer'

      renderer = Tooling::DastVariables::Docs::Renderer.new(**dast_variables_render_options)

      renderer.write

      puts "Documentation compiled."
    end

    desc 'GitLab | DAST variables | Check if docs are up to date'
    task check_docs: [:environment] do
      require_relative '../../../tooling/dast_variables/docs/renderer'

      renderer = Tooling::DastVariables::Docs::Renderer.new(**dast_variables_render_options)

      doc = File.read(dast_variables_render_options[:output_file])

      unless doc == renderer.contents
        raise <<~ERROR_MESSAGE.strip
        DAST variables documentation is outdated!
        Please update it by running `bundle exec rake gitlab:dast_variables:compile_docs`.
        ERROR_MESSAGE
      end

      puts "DAST variables documentation is up to date"
    end

    def dast_variables_render_options
      {
        output_file: Rails.root.join("doc/user/application_security/dast/browser/configuration/variables.md"),
        template: Rails.root.join("tooling/dast_variables/docs/templates/default.md.haml")
      }
    end
  end
end
