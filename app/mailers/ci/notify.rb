module Ci
  class Notify < ActionMailer::Base
    include Ci::Emails::Builds

    add_template_helper Ci::GitlabHelper

    default_url_options[:host]     = Gitlab.config.gitlab.host
    default_url_options[:protocol] = Gitlab.config.gitlab.protocol
    default_url_options[:port]     = Gitlab.config.gitlab.port unless Gitlab.config.gitlab_on_standard_port?
    default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

    default from: Gitlab.config.gitlab.email_from

    # Just send email with 3 seconds delay
    def self.delay
      delay_for(2.seconds)
    end

    private

    # Formats arguments into a String suitable for use as an email subject
    #
    # extra - Extra Strings to be inserted into the subject
    #
    # Examples
    #
    #   >> subject('Lorem ipsum')
    #   => "GitLab-CI | Lorem ipsum"
    #
    #   # Automatically inserts Project name when @project is set
    #   >> @project = Project.last
    #   => #<Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
    #   >> subject('Lorem ipsum')
    #   => "GitLab-CI | Ruby on Rails | Lorem ipsum "
    #
    #   # Accepts multiple arguments
    #   >> subject('Lorem ipsum', 'Dolor sit amet')
    #   => "GitLab-CI | Lorem ipsum | Dolor sit amet"
    def subject(*extra)
      subject = "GitLab-CI"
      subject << (@project ? " | #{@project.name}" : "")
      subject << " | " + extra.join(' | ') if extra.present?
      subject
    end
  end
end
