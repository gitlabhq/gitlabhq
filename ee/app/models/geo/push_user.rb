# frozen_string_literal: true

class Geo::PushUser
  include ::Gitlab::Identifier

  def initialize(gl_id)
    @gl_id = gl_id
  end

  def self.needed_headers_provided?(headers)
    headers['Geo-GL-Id'].present?
  end

  def self.new_from_headers(headers)
    return nil unless needed_headers_provided?(headers)

    new(headers['Geo-GL-Id'])
  end

  def user
    @user ||= identify_using_ssh_key(gl_id)
  end

  private

  attr_reader :gl_id
end
