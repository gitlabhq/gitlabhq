# frozen_string_literal: true

# MIT License
#
# Copyright (c) 2021 package-url
# Portions Copyright 2022 Gitlab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Sbom
  class PackageUrl
    class Encoder
      include StringUtils

      def initialize(package)
        @type = package.type
        @namespace = package.namespace
        @name = package.name
        @version = package.version
        @qualifiers = package.qualifiers
        @subpath = package.subpath
        @io = StringIO.new
      end

      def encode
        encode_scheme!
        encode_type!
        encode_name!
        encode_version!
        encode_qualifiers!
        encode_subpath!

        io.string
      end

      private

      attr_reader :io

      def encode_scheme!
        io.write('pkg:')
      end

      def encode_type!
        # Append the type string to the purl as a lowercase ASCII string
        # Append '/' to the purl
        io.write(@type)
        io.write('/')
      end

      def encode_name!
        # If the namespace is empty:
        # - Apply type-specific normalization to the name if needed
        # - UTF-8-encode the name if needed in your programming language
        # - Append the percent-encoded name to the purl
        #
        # If the namespace is not empty:
        # - Strip the namespace from leading and trailing '/'
        # - Split on '/' as segments
        # - Apply type-specific normalization to each segment if needed
        # - UTF-8-encode each segment if needed in your programming language
        # - Percent-encode each segment
        # - Join the segments with '/'
        # - Append this to the purl
        # - Append '/' to the purl
        # - Strip the name from leading and trailing '/'
        # - Apply type-specific normalization to the name if needed
        # - UTF-8-encode the name if needed in your programming language
        # - Append the percent-encoded name to the purl
        if @namespace.present?
          normalized_namespace = Normalizer.new(type: @type, text: @namespace).normalize_namespace
          io.write(encode_segments(normalized_namespace, &:empty?))
          io.write('/')
        end

        normalized_name = Normalizer.new(type: @type, text: strip(@name, '/')).normalize_name
        io.write(URI.encode_www_form_component(normalized_name, Encoding::UTF_8))
      end

      def encode_version!
        return if @version.nil?

        # - Append '@' to the purl
        # - UTF-8-encode the version if needed in your programming language
        # - Append the percent-encoded version to the purl
        io.write('@')
        io.write(URI.encode_www_form_component(@version, Encoding::UTF_8))
      end

      def encode_qualifiers!
        return if @qualifiers.nil? || encoded_qualifiers.empty?

        io.write('?')
        io.write(encoded_qualifiers)
      end

      def encoded_qualifiers
        @encoded_qualifiers ||= @qualifiers.filter_map do |key, value|
          next if value.empty?

          next "#{key.downcase}=#{value.join(',')}" if key == 'checksums' && value.is_a?(::Array)

          "#{key.downcase}=#{URI.encode_www_form_component(value, Encoding::UTF_8)}"
        end.sort.join('&')
      end

      def encode_subpath!
        return if @subpath.nil? || encoded_subpath.empty?

        io.write('#')
        io.write(encoded_subpath)
      end

      def encoded_subpath
        @encoded_subpath ||= encode_segments(@subpath) do |segment|
          # Discard segments which are blank, `.`, or `..`
          segment.empty? || segment == '.' || segment == '..'
        end
      end
    end
  end
end
