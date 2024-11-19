# frozen_string_literal: true

if RUBY_PLATFORM.include?('darwin')
  require 'fiddle'
  require 'ffi'
  require 'ethon'

  module CFTimeZone
    extend FFI::Library

    ffi_lib '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'
    attach_function :CFTimeZoneCopyDefault, [], :pointer
    attach_function :CFTimeZoneGetName, [:pointer], :pointer
    attach_function :CFRelease, [:pointer], :void
  end

  # Dynamically load Foundation.framework, ~implicitly~ initialising
  # the Objective-C runtime before any forking happens in webserver
  #
  # From https://bugs.ruby-lang.org/issues/14009
  Fiddle.dlopen '/System/Library/Frameworks/Foundation.framework/Foundation'

  # grpc uses abseil-cpp to retrieve the local time zone via macOS APIs:
  # https://github.com/abseil/abseil-cpp/blob/20230125.rc3/absl/time/internal/cctz/src/time_zone_lookup.cc#L139
  #
  # To ensure these APIs are not called in a forked process (https://github.com/grpc/grpc/issues/26257),
  # load the required framework, retrieve the default time zone, and then release the resource.
  default_time_zone = CFTimeZone.CFTimeZoneCopyDefault
  time_zone_name = CFTimeZone.CFTimeZoneGetName(default_time_zone)
  CFTimeZone.CFRelease(time_zone_name)
  CFTimeZone.CFRelease(default_time_zone)

  # With curl v8.2.0, the thread unsafe macOS API call to
  # SCDynamicStoreCopyProxies has been moved to the global init function
  # (https://github.com/curl/curl/issues/11252). The Elasticsearch
  # gem uses Typhoeus, which uses Ethon to wrap libcurl.
  # Init curl to ensure Spring works
  # (https://github.com/elastic/elasticsearch-ruby/issues/2244).
  Ethon::Curl.init
end
