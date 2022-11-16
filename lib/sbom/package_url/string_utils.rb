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
    module StringUtils
      private

      def strip(string, char)
        string = string.delete_prefix(char) while string.start_with?(char)
        string = string.delete_suffix(char) while string.end_with?(char)
        string
      end

      def split_segments(string)
        strip(string, '/').split('/')
      end

      def encode_segments(string)
        return '' if string.nil?

        split_segments(string).map do |segment|
          next if block_given? && yield(segment)

          URI.encode_www_form_component(segment)
        end.join('/')
      end

      # Partition the given string on the separator.
      # The side being partitioned from is returned as the value,
      # with the opposing side being returned as the remainder.
      #
      # If a block is given, then the (value, remainder) are given
      # to the block, and the return value of the block is used as the value.
      #
      # If `require_separator` is true, then a nil value will be returned
      # if the separator is not present.
      def partition(string, sep, from: :left, require_separator: true)
        value, separator, remainder = if from == :left
                                        left, separator, right = string.partition(sep)
                                        [left, separator, right]
                                      else
                                        left, separator, right = string.rpartition(sep)
                                        [right, separator, left]
                                      end

        return [nil, value] if separator.empty? && require_separator

        value = yield(value) if block_given?

        [value, remainder]
      end
    end
  end
end
