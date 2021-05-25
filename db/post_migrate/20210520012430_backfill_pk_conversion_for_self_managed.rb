# frozen_string_literal: true

class BackfillPkConversionForSelfManaged < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONVERSIONS = [
    { table: :events, columns: %i(id), sub_batch_size: 500 },
    { table: :push_event_payloads, columns: %i(event_id), sub_batch_size: 2500, primary_key: :event_id },
    { table: :ci_job_artifacts, columns: %i(id job_id), sub_batch_size: 2000 },
    { table: :ci_sources_pipelines, columns: %i(source_job_id), sub_batch_size: 100 },
    { table: :ci_build_needs, columns: %i(build_id), sub_batch_size: 1000 },
    { table: :ci_builds, columns: %i(id stage_id), sub_batch_size: 250 },
    { table: :ci_builds_runner_session, columns: %i(build_id), sub_batch_size: 5000 },
    { table: :ci_build_trace_chunks, columns: %i(build_id), sub_batch_size: 1000 }
  ]

  def up
    return unless should_run?

    CONVERSIONS.each do |conversion|
      backfill_conversion_of_integer_to_bigint(
        conversion[:table], conversion[:columns],
        sub_batch_size: conversion[:sub_batch_size], primary_key: conversion.fetch(:primary_key, :id)
      )
    end
  end

  def down
    return unless should_run?

    CONVERSIONS.each do |conversion|
      revert_backfill_conversion_of_integer_to_bigint(
        conversion[:table], conversion[:columns],
        primary_key: conversion.fetch(:primary_key, :id)
      )
    end
  end

  private

  def should_run?
    !Gitlab.com?
  end
end
