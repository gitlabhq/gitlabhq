---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Beginner's guide to writing end-to-end tests
---

This tutorial walks you through the creation of end-to-end (_e2e_) tests for [GitLab Community Edition](https://about.gitlab.com/install/?version=ce) and [GitLab Enterprise Edition](https://about.gitlab.com/install/).

By the end of this tutorial, you can:

- Determine whether an end-to-end test is needed.
- Understand the directory structure within `qa/`.
- Write a basic end-to-end test that validates login features.
- Develop any missing [page object](page_objects.md) libraries.

## Before you write a test

Before you write tests, your [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit) must be configured to run the specs. The end-to-end tests:

- Are contained within the `qa/` directory.
- Should be independent and [idempotent](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning).
- Create [resources](resources.md) (such as project, issue, user) on an ad-hoc basis.
- Test the UI and API interfaces, and use the API to efficiently set up the UI tests.

## Determine if end-to-end tests are needed

Check the code coverage of a specific feature before writing end-to-end tests for the [GitLab](https://gitlab-org.gitlab.io/gitlab/coverage-ruby/#_AllFiles) project. Does sufficient test coverage exist at the unit, feature, or integration levels? If you answered *yes*, then you *don't* need an end-to-end test.

For information about the distribution of tests per level in GitLab, see [Testing Levels](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/testing_guide/testing_levels.md).

- See the [How to test at the correct level?](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/testing_guide/testing_levels.md#how-to-test-at-the-correct-level) section of the [Testing levels](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/testing_guide/testing_levels.md) document.
- Review how often the feature changes. Stable features that don't change very often might not be worth covering with end-to-end tests if they are already covered in lower level tests.
- Finally, discuss the proposed test with the developers involved in implementing the feature and the lower-level tests.

WARNING:
Check the [GitLab](https://gitlab-org.gitlab.io/gitlab/coverage-ruby/#_AllFiles) coverage project for previously written tests for this feature. To analyze code coverage, you must understand which application files implement specific features.

In this tutorial we're writing a login end-to-end test, even though it has been sufficiently covered by lower-level testing, because it's the first step for most end-to-end flows, and is easiest to understand.

## Identify the DevOps stage

The GitLab QA end-to-end tests are organized by the different [stages in the DevOps lifecycle](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/qa/qa/specs/features/browser_ui). Determine where the test should be placed by [stage](https://handbook.gitlab.com/handbook/product/categories/#devops-stages), determine which feature the test belongs to, and then place it in a subdirectory under the stage.

![DevOps lifecycle by stages](../img/gl-devops-lifecycle-by-stage_v12_10.png)

If the test is Enterprise Edition only, the test is created in the `features/ee` directory, but follow the same DevOps lifecycle format.

## Create a skeleton test

In the first part of this tutorial we are testing login, which is owned by the Manage stage. Inside `qa/specs/features/browser_ui/1_manage/login`, create a file `basic_login_spec.rb`.

### The outer `context` block

See the [`RSpec.describe` outer block](#the-outer-rspecdescribe-block)

WARNING:
The outer `context` [was deprecated](https://gitlab.com/gitlab-org/quality/quality-engineering/team-tasks/-/issues/550) in `13.2` in adherence to RSpec 4.0 specifications. Use `RSpec.describe` instead.

### The outer `RSpec.describe` block

Specs have an outer `RSpec.describe` indicating the DevOps stage.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do

  end
end
```

### The `describe` block

Inside of our outer `RSpec.describe`, describe the feature to test. In this case, `Login`.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Login' do

    end
  end
end
```

### The `product_group` metadata

Assign `product_group` metadata and specify what product group this test belongs to. In this case, `authentication_and_authorization`.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Login', product_group: :authentication do

    end
  end
end
```

### The `it` blocks (examples)

Every test suite contains at least one `it` block (example). A good way to start writing end-to-end tests is to write test case descriptions as `it` blocks:

```ruby
module QA
  RSpec.describe 'Manage' do
    describe 'Login', product_group: :authentication do
      it 'can login' do

      end

      it 'can logout' do

      end
    end
  end
end
```

## Write the test

An important question is "What do we test?" and even more importantly, "How do we test?"

Begin by logging in.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Login', product_group: :authentication do
      it 'can login' do
        Flow::Login.sign_in

      end

      it 'can logout' do
        Flow::Login.sign_in

      end
    end
  end
end
```

NOTE:
For more information on Flows, see [Flows](flows.md)

After [running the spec](#run-the-spec), our test should login and end; then we should answer the question "What do we test?"

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Login', product_group: :authentication do
      it 'can login' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          expect(menu).to be_signed_in
        end
      end

      it 'can logout' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          menu.sign_out

          expect(menu).not_to be_signed_in
        end
      end
    end
  end
end
```

**What do we test?**

1. Can we sign in?
1. Can we sign out?

**How do we test?**

1. Check if the user avatar appears in the left sidebar.
1. Check if the user avatar *does not* appear in the left sidebar.

Behind the scenes, `be_signed_in` is a [predicate matcher](https://rspec.info/features/3-12/rspec-expectations/built-in-matchers/predicates/) that [implements checking the user avatar](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/page/main/menu.rb#L92).

## De-duplicate your code

Refactor your test to use a `before` block for test setup, since it's duplicating a call to `sign_in`.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Login', product_group: :authentication do
      before do
        Flow::Login.sign_in
      end

      it 'can login' do
        Page::Main::Menu.perform do |menu|
          expect(menu).to be_signed_in
        end
      end

      it 'can logout' do
        Page::Main::Menu.perform do |menu|
          menu.sign_out

          expect(menu).not_to be_signed_in
        end
      end
    end
  end
end
```

The `before` block is essentially a `before(:each)` and is run before each example, ensuring we now sign in at the beginning of each test.

## Test setup using resources and page objects

Next, let's test something other than Login. Let's test Issues, which are owned by the Plan stage and the Project Management Group, so [create a file](#identify-the-devops-stage) in `qa/specs/features/browser_ui/2_plan/issue` called `issues_spec.rb`.

```ruby
# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Issues', product_group: :project_management do
      let(:issue) { create(:issue) }

      before do
        Flow::Login.sign_in
        issue.visit!
      end

      it 'can close an issue' do
        Page::Project::Issue::Show.perform do |show|
          show.click_close_issue_button

          expect(show).to be_closed
        end
      end
    end
  end
end
```

Note the following important points:

- At the start of our example, we are at the `page/issue/show.rb` [page](page_objects.md).
- Our test fabricates only what it needs, when it needs it.
- The issue is fabricated through the API to save time.
- GitLab prefers `let()` over instance variables. See [best practices](../../best_practices.md#subject-and-let-variables).
- `be_closed` is not implemented in `page/project/issue/show.rb` yet, but is implemented in the next step.

The issue is fabricated as a [Resource](resources.md), which is a GitLab entity you can create through the UI or API. Other examples include:

- A [Merge Request](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/resource/merge_request.rb).
- A [User](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/resource/user.rb).
- A [Project](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/resource/project.rb).
- A [Group](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/resource/group.rb).

## Write the page object

A [Page Object](page_objects.md) is a class in our suite that represents a page within GitLab. The **Login** page would be one example. Since our page object for the **Issue Show** page already exists, add the `closed?` method.

```ruby
module Page::Project::Issue
  class Show
    view 'app/views/projects/issues/show.html.haml' do
      element 'closed-status-box'
    end

    def closed?
      has_element?('closed-status-box')
    end
  end
end
```

Next, define the element `closed-status-box` within your view, so your Page Object can see it.

```haml
-#=> app/views/projects/issues/show.html.haml
.issuable-status-box.status-box.status-box-issue-closed{ ..., data: { testid: 'closed-status-box' } }
```

## Run the spec

Before running the spec, make sure that:

- GDK is installed.
- GDK is running locally on port 3000.
- No additional [RSpec metadata tags](../best_practices/rspec_metadata_tests.md) have been applied.
- Your working directory is `qa/` within your GDK GitLab installation.
- Your GitLab instance-level settings are default. If you changed the default settings, some tests might have unexpected results.
- Because the GDK requires a password change on first login, you must include the GDK password for `root` user

To run the spec, run the following command:

```shell
GITLAB_PASSWORD=<GDK root password> bundle exec rspec <test_file>
```

Where `<test_file>` is:

- `qa/specs/features/browser_ui/1_manage/login/log_in_spec.rb` when running the Login example.
- `qa/specs/features/browser_ui/2_plan/issue/create_issue_spec.rb` when running the Issue example.

Additional information on test execution and possible options are described in ["QA framework README"](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/README.md#run-the-end-to-end-tests-in-a-local-development-environment)

## Preparing test for code review

Before submitting the test for code review, there are a few housecleaning tasks to do:

1. Ensure that the test name follows the recommended [naming convention](../best_practices/_index.md#test-naming).
1. Ensure that the spec is [linked to a test case](../best_practices/_index.md#link-a-test-to-its-test-case).
1. Ensure that the spec has the correct `product_group` metadata. See [Product sections, stages, groups, and categories](https://handbook.gitlab.com/handbook/product/categories/) for the comprehensive list of groups.
1. Ensure that the relevant [RSpec metadata](../best_practices/rspec_metadata_tests.md) are added to the spec.
1. Ensure the page object elements are named according to the [recommended naming convention](../style_guide.md#element-naming-convention).

NOTE:
For more information, see [End-to-end testing best practices](../best_practices/_index.md) and [End-to-end testing style guide](../style_guide.md).

## End-to-end test merge request template

When submitting a new end-to-end test, use the ["New End to End Test"](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/New%20End%20To%20End%20Test.md) merge request description template for additional steps that are required prior a successful merge.
