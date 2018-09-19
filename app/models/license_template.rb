# frozen_string_literal: true

class LicenseTemplate
  PROJECT_TEMPLATE_REGEX =
    %r{[\<\{\[]
      (project|description|
      one\sline\s.+\swhat\sit\sdoes\.) # matching the start and end is enough here
    [\>\}\]]}xi.freeze
  YEAR_TEMPLATE_REGEX = /[<{\[](year|yyyy)[>}\]]/i.freeze
  FULLNAME_TEMPLATE_REGEX =
    %r{[\<\{\[]
      (fullname|name\sof\s(author|copyright\sowner))
    [\>\}\]]}xi.freeze

  attr_reader :id, :name, :category, :nickname, :url, :meta

  alias_method :key, :id

  def initialize(id:, name:, category:, content:, nickname: nil, url: nil, meta: {})
    @id = id
    @name = name
    @category = category
    @content = content
    @nickname = nickname
    @url = url
    @meta = meta
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
  def resolve!(project_name: nil, fullname: nil, year: Time.now.year.to_s)
    # Ensure the string isn't shared with any other instance of LicenseTemplate
    new_content = content.dup
    new_content.gsub!(YEAR_TEMPLATE_REGEX, year) if year.present?
    new_content.gsub!(PROJECT_TEMPLATE_REGEX, project_name) if project_name.present?
    new_content.gsub!(FULLNAME_TEMPLATE_REGEX, fullname) if fullname.present?

    @content = new_content

    self
  end
end
