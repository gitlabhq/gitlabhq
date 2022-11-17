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
  # A package URL, or _purl_, is a URL string used to
  # identify and locate a software package in a mostly universal and uniform way
  # across programing languages, package managers, packaging conventions, tools,
  # APIs and databases.
  #
  # A purl is a URL composed of seven components:
  #
  # ```
  # scheme:type/namespace/name@version?qualifiers#subpath
  # ```
  #
  # For example,
  # the package URL for this Ruby package at version 0.1.0 is
  # `pkg:ruby/mattt/packageurl-ruby@0.1.0`.
  #
  # More details on the package URL format can be found in the purl specification:
  # https://github.com/package-url/purl-spec/blob/0b1559f76b79829e789c4f20e6d832c7314762c5/PURL-SPECIFICATION.rst
  class PackageUrl
    # Raised when attempting to parse an invalid package URL string.
    # @see #parse
    InvalidPackageUrl = Class.new(ArgumentError)

    # The URL scheme, which has a constant value of `"pkg"`.
    def scheme
      'pkg'
    end

    # The package type or protocol, such as `"gem"`, `"npm"`, and `"github"`.
    attr_reader :type

    # A name prefix, specific to the type of package.
    # For example, an npm scope, a Docker image owner, or a GitHub user.
    attr_reader :namespace

    # The name of the package.
    attr_reader :name

    # The version of the package.
    attr_reader :version

    # Extra qualifying data for a package, specific to the type of package.
    # For example, the operating system or architecture.
    attr_reader :qualifiers

    # An extra subpath within a package, relative to the package root.
    attr_reader :subpath

    # Constructs a package URL from its components
    # @param type [String] The package type or protocol.
    # @param namespace [String] A name prefix, specific to the type of package.
    # @param name [String] The name of the package.
    # @param version [String] The version of the package.
    # @param qualifiers [Hash] Extra qualifying data for a package, specific to the type of package.
    # @param subpath [String] An extra subpath within a package, relative to the package root.
    def initialize(type:, name:, namespace: nil, version: nil, qualifiers: nil, subpath: nil)
      @type = type&.downcase
      @namespace = namespace
      @name = name
      @version = version
      @qualifiers = qualifiers
      @subpath = subpath

      ArgumentValidator.new(self).validate!
    end

    # Creates a new PackageUrl from a string.
    # @param [String] string The package URL string.
    # @raise [InvalidPackageUrl] If the string is not a valid package URL.
    # @return [PackageUrl]
    def self.parse(string)
      Decoder.new(string).decode!
    end

    # Returns a hash containing the
    # scheme, type, namespace, name, version, qualifiers, and subpath components
    # of the package URL.
    def to_h
      {
        scheme: scheme,
        type: @type,
        namespace: @namespace,
        name: @name,
        version: @version,
        qualifiers: @qualifiers,
        subpath: @subpath
      }
    end

    # Returns a string representation of the package URL.
    # Package URL representations are created according to the instructions from
    # https://github.com/package-url/purl-spec/blob/0b1559f76b79829e789c4f20e6d832c7314762c5/PURL-SPECIFICATION.rst#how-to-build-purl-string-from-its-components.
    def to_s
      Encoder.new(self).encode
    end
  end
end
