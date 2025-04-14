# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  around_action :render_with_default_locale

  helper ApplicationHelper
  helper MarkupHelper

  attr_accessor :current_user

  helper_method :current_user, :can?

  default from:     proc { default_sender_address.format }
  default reply_to: proc { default_reply_to_address.format }

  def can?
    Ability.allowed?(current_user, action, subject)
  end

  private

  # Formats arguments into a String suitable for use as an email subject
  #
  # extra - Extra Strings to be inserted into the subject
  #
  # Examples
  #
  #   >> subject('Lorem ipsum')
  #   => "Lorem ipsum"
  #
  #   # Automatically inserts Project name when @project is set
  #   >> @project = Project.last
  #   => #<Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   >> subject('Lorem ipsum')
  #   => "Ruby on Rails | Lorem ipsum "
  #
  #   # Accepts multiple arguments
  #   >> subject('Lorem ipsum', 'Dolor sit amet')
  #   => "Lorem ipsum | Dolor sit amet"
  def subject(*extra)
    subject = []

    subject << @project.name if @project
    subject << @group.name if @group
    subject << @namespace.name if @namespace && !@project
    subject.concat(extra) if extra.present?

    EmailsHelper.subject_with_suffix(subject)
  end

  def render_with_default_locale(&block)
    Gitlab::I18n.with_default_locale(&block)
  end

  def default_sender_address
    address = Mail::Address.new(Gitlab.config.gitlab.email_from)
    address.display_name = Gitlab.config.gitlab.email_display_name
    address
  end

  def default_reply_to_address
    address = Mail::Address.new(Gitlab.config.gitlab.email_reply_to)
    address.display_name = Gitlab.config.gitlab.email_display_name
    address
  end

  def mail_with_locale(headers = {}, &block)
    locale = recipient_locale headers

    Gitlab::I18n.with_locale(locale) do
      mail(headers, &block)
    end
  end

  def recipient_locale(headers = {})
    to = Array(headers[:to])
    locale = I18n.locale
    locale = preferred_language_by_email(to.first) if to.one?
    locale
  end

  def preferred_language_by_email(email)
    User.find_by_any_email(email)&.preferred_language || I18n.locale
  end
end
