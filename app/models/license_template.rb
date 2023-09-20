# frozen_string_literal: true

class LicenseTemplate
  PROJECT_TEMPLATE_REGEX =
    %r{[\<\{\[]
      (project|description|
      one\sline\s.+\swhat\sit\sdoes\.) # matching the start and end is enough here
    [\>\}\]]}xi
  YEAR_TEMPLATE_REGEX = /[<{\[](year|yyyy)[>}\]]/i
  FULLNAME_TEMPLATE_REGEX =
    %r{[\<\{\[]
      (fullname|name\sof\s(author|copyright\sowner))
    [\>\}\]]}xi

  attr_reader :key, :name, :project, :category, :nickname, :url, :meta

  def initialize(key:, name:, project:, category:, content:, nickname: nil, url: nil, meta: {})
    @key = key
    @name = name
    @project = project
    @category = category
    @content = content
    @nickname = nickname
    @url = url
    @meta = meta
  end

  def project_id
    project&.id
  end

  def popular?
    category == :Popular
  end
  alias_method :featured?, :popular?

  # Returns the text of the license
  def content
    if @content.respond_to?(:call)
      @content = @content.call
    else
      @content
    end
  end

  # Populate placeholders in the LicenseTemplate content
  def resolve!(project_name: nil, fullname: nil, year: Time.current.year.to_s)
    # Ensure the string isn't shared with any other instance of LicenseTemplate
    new_content = content.dup
    new_content.gsub!(YEAR_TEMPLATE_REGEX, year) if year.present?
    new_content.gsub!(PROJECT_TEMPLATE_REGEX, project_name) if project_name.present?
    new_content.gsub!(FULLNAME_TEMPLATE_REGEX, fullname) if fullname.present?

    @content = new_content

    self
  end
end
