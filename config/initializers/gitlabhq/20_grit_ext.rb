require 'grit'
require 'pygments'
require "utils"

Grit::Blob.class_eval do
  include Utils::FileHelper
  include Utils::Colorize
end

#monkey patch raw_object from string
Grit::GitRuby::Internal::RawObject.class_eval do
  def content
    transcoding(@content)
  rescue Exception => ex
    Rails.logger.error ex.message
    @content
  end

  private
  def transcoding(content)
    content ||= ""
    detection = CharlockHolmes::EncodingDetector.detect(content)
    if hash = detection
     content = CharlockHolmes::Converter.convert(content, hash[:encoding], 'UTF-8') if hash[:encoding]
    end
    content
  end
end


Grit::Git.git_timeout = GIT_OPTS["git_timeout"]
Grit::Git.git_max_size = GIT_OPTS["git_max_size"]
