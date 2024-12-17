# frozen_string_literal: true

module Packages
  module Nuget
    module VersionHelpers
      private

      def sort_versions(versions)
        versions.sort { |a, b| compare_versions(a, b) }
      end

      # NuGet version sorting algorithm as per https://semver.org/spec/v2.0.0.html#spec-item-11
      def compare_versions(version_a, version_b)
        return 0 if version_a == version_b
        return 1 if version_b.nil?
        return -1 if version_a.nil?

        a_without_build_meta, a_build_meta = version_a.split('+', 2)
        b_without_build_meta, b_build_meta = version_b.split('+', 2)

        a_core, a_pre = a_without_build_meta.split(/-/, 2)
        b_core, b_pre = b_without_build_meta.split(/-/, 2)

        a_core_parts = a_core.split('.')
        b_core_parts = b_core.split('.')

        compare_core_parts(a_core_parts, b_core_parts) ||
          compare_pre_release_parts(a_pre, b_pre) ||
          pick_non_nil(a_pre, b_pre) ||
          compare_build_meta_parts(a_build_meta, b_build_meta)
      end

      def compare_core_parts(a_core_parts, b_core_parts)
        while a_core_parts.any? || b_core_parts.any?
          a_part = a_core_parts.shift.to_i
          b_part = b_core_parts.shift.to_i
          return a_part <=> b_part if a_part != b_part
        end
      end

      def compare_pre_release_parts(a_pre, b_pre)
        return unless a_pre && b_pre

        a_pre_parts = a_pre.split('.').map(&:downcase)
        b_pre_parts = b_pre.split('.').map(&:downcase)

        while a_pre_parts.any? || b_pre_parts.any?
          a_pre_part = a_pre_parts.shift
          b_pre_part = b_pre_parts.shift

          # Empty parts are considered lower
          return -1 if a_pre_part.nil?
          return 1 if b_pre_part.nil?

          a_num = a_pre_part.to_i
          b_num = b_pre_part.to_i
          next if a_num == b_num && a_pre_part.to_s == b_pre_part.to_s # Both are same numeric/alphanumeric parts

          return select_numeric_before_alphanumeric(a_num, a_pre_part, b_num, b_pre_part) ||
              compare_numeric_parts(a_pre_part, a_num, b_pre_part, b_num) ||
              a_pre_part <=> b_pre_part
        end
      end

      def compare_build_meta_parts(a_build_meta, b_build_meta)
        (a_build_meta || '').casecmp(b_build_meta || '')
      end

      def select_numeric_before_alphanumeric(a_num, a_pre_part, b_num, b_pre_part)
        return -1 if a_num != b_num && numeric?(a_pre_part) && !numeric?(b_pre_part)
        return 1 if a_num != b_num && !numeric?(a_pre_part) && numeric?(b_pre_part)
      end

      def numeric?(pre_part)
        !!Integer(pre_part, exception: false)
      end

      def compare_numeric_parts(a_pre_part, a_num, b_pre_part, b_num)
        a_num <=> b_num if a_num != b_num && numeric?(a_pre_part) && numeric?(b_pre_part)
      end

      def pick_non_nil(var_a, var_b)
        return -1 if var_a && !var_b
        return 1 if !var_a && var_b
      end
    end
  end
end
