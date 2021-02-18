# frozen_string_literal: true

# The method `filename` must be defined in classes that mix in this module.
#
# This module is intended to be used as a helper and not a security gate
# to validate that a file is safe, as it identifies files only by the
# file extension and not its actual contents.
#
# An example useage of this module is in `FileMarkdownLinkBuilder` that
# renders markdown depending on a file name.
#
# We use Workhorse to detect the real extension when we serve files with
# the `SendsBlob` helper methods, and ask Workhorse to set the content
# type when it serves the file:
# https://gitlab.com/gitlab-org/gitlab/blob/33e5955/app/helpers/workhorse_helper.rb#L48.
#
# Because Workhorse has access to the content when it is downloaded, if
# the type/extension doesn't match the real type, we adjust the
# `Content-Type` and `Content-Disposition` to the one we get from the detection.
module Gitlab
  module FileTypeDetection
    SAFE_IMAGE_EXT = %w[png jpg jpeg gif bmp tiff ico webp].freeze
    SAFE_IMAGE_FOR_SCALING_EXT = %w[png jpg jpeg].freeze

    PDF_EXT = 'pdf'
    # We recommend using the .mp4 format over .mov. Videos in .mov format can
    # still be used but you really need to make sure they are served with the
    # proper MIME type video/mp4 and not video/quicktime or your videos won't play
    # on IE >= 9.
    # http://archive.sublimevideo.info/20150912/docs.sublimevideo.net/troubleshooting.html
    SAFE_VIDEO_EXT = %w[mp4 m4v mov webm ogv].freeze
    SAFE_AUDIO_EXT = %w[mp3 oga ogg spx wav].freeze

    # These extension types can contain dangerous code and should only be embedded inline with
    # proper filtering. They should always be tagged as "Content-Disposition: attachment", not "inline".
    DANGEROUS_IMAGE_EXT = %w[svg].freeze
    DANGEROUS_VIDEO_EXT = [].freeze # None, yet
    DANGEROUS_AUDIO_EXT = [].freeze # None, yet

    def self.extension_match?(filename, extensions)
      return false unless filename.present?

      extension = File.extname(filename).delete('.')
      extensions.include?(extension.downcase)
    end

    def image?
      extension_match?(SAFE_IMAGE_EXT)
    end

    # For the time being, we restrict image scaling requests to the most popular and safest formats only,
    # which are JPGs and PNGs. See https://gitlab.com/gitlab-org/gitlab/-/issues/237848 for more info.
    def image_safe_for_scaling?
      extension_match?(SAFE_IMAGE_FOR_SCALING_EXT)
    end

    def video?
      extension_match?(SAFE_VIDEO_EXT)
    end

    def audio?
      extension_match?(SAFE_AUDIO_EXT)
    end

    def pdf?
      extension_match?([PDF_EXT])
    end

    def embeddable?
      image? || video? || audio?
    end

    def dangerous_image?
      extension_match?(DANGEROUS_IMAGE_EXT)
    end

    def dangerous_video?
      extension_match?(DANGEROUS_VIDEO_EXT)
    end

    def dangerous_audio?
      extension_match?(DANGEROUS_AUDIO_EXT)
    end

    def dangerous_embeddable?
      dangerous_image? || dangerous_video? || dangerous_audio?
    end

    private

    def extension_match?(extensions)
      ::Gitlab::FileTypeDetection.extension_match?(filename, extensions)
    end
  end
end
