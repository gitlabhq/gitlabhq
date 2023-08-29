---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sentry

As part of the [Frontend Observability Working Group](https://google.com) we're looking to provide documentation on how to use Sentry effectively.
If left unchecked, Sentry can get noisy and become unreliable.
This page aims to help guide us toward more sensible Sentry usage.

## Which errors we should report to Sentry explicitly and which should be only shown to users (e.g. as alerts)

If we send all errors to Sentry, it gets very noisy, very quickly.
We want to filter out the errors that we either don't care about, or have no control over.
For example, if a user fills out a form incorrectly, this is not something we want to send to Sentry.
If that form fails because it's hitting a dead endpoint, this is an error we want Sentry to know about.

## How to catch errors correctly so Sentry can display them reliably

TBD

## How to catch special cases you want to track (like we did with the pipeline graph)

TBD

## How to navigate Sentry and find errors

TBD

## How to debug Sentry errors effectively

TBD
