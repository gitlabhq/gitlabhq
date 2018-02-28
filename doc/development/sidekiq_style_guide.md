# Sidekiq Style Guide

This document outlines various guidelines that should be followed when adding or
modifying Sidekiq workers.

## ApplicationWorker

All workers should include `ApplicationWorker` instead of `Sidekiq::Worker`,
which adds some convenience methods and automatically sets the queue based on
the worker's name.

## Default Queue

Use of the "default" queue is not allowed. Every worker should use a queue that
matches the worker's purpose the closest. For example, workers that are to be
executed periodically should use the "cronjob" queue.

A list of all available queues can be found in `config/sidekiq_queues.yml`.

## Dedicated Queues

Most workers should use their own queue, which is automatically set based on the
worker class name. For a worker named `ProcessSomethingWorker`, the queue name
would be `process_something`. If you're not sure what a worker's queue name is,
you can find it using `SomeWorker.queue`.

In some cases multiple workers do use the same queue. For example, the various
workers for updating CI pipelines all use the `pipeline` queue. Adding workers
to existing queues should be done with care, as adding more workers can lead to
slow jobs blocking work (even for different jobs) on the shared queue.

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.

## Removing or renaming queues

Try to avoid renaming or removing queues in minor and patch releases.
During online update instance can have pending jobs and removing the queue can
lead to those jobs being stuck forever. If you can't write migration for those
Sidekiq jobs, please consider doing rename or remove queue in major release only.
