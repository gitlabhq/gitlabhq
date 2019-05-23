# Writing end-to-end tests step-by-step

In this tutorial, you will find different examples, and the steps involved, in the creation of end-to-end (_e2e_) tests for GitLab CE and GitLab EE, using GitLab QA.

> When referring to end-to-end tests in this document, this means testing a specific feature end-to-end, such as a user logging in, the creation of a project, the management of labels, breaking down epics into sub-epics and issues, etc.

## Important information before we start writing tests

It's important to understand that end-to-end tests of isolated features, such as the ones described in the above note, doesn't mean that everything needs to happen through the GUI.

If you don't exactly understand what we mean by **not everything needs to happen through the GUI,** please make sure you've read the [best practices](./BEST_PRACTICES.md) before moving on.

## This document covers the following items:

0. Identifying if end-to-end tests are really needed
1. Identifying the [DevOps stage](https://about.gitlab.com/stages-devops-lifecycle/) of the feature that you are going to cover with end-to-end tests
2. Creating the skeleton of the test file (`*_spec.rb`)
3. The [MVC](https://about.gitlab.com/handbook/values/#minimum-viable-change-mvc) of the test cases logic
4. Extracting duplicated code into methods
5. Tests' pre-conditions (`before :all` and `before`) using resources and [Page Objects](./qa/page/README.md)
6. Optimizing the test suite
7. Using and implementing resources
8. Moving elements definitions and its methods to [Page Objects](./qa/page/README.md)
    - Adding testability to the application

### 0. Are end-to-end tests needed?

At GitLab we respect the [test pyramid](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/development/testing_guide/testing_levels.md), and so, we recommend to check the code coverage of a specific feature before writing end-to-end tests.

Sometimes you may notice that there is already a good coverage in other test levels, and we can stay confident that if we break a feature, we will still have quick feedback about it, even without having end-to-end tests.

If after this analysis you still think that end-to-end tests are needed, keep reading.

### 1. Identifying the DevOps stage

The GitLab QA end-to-end tests are organized by the different [stages in the DevOps lifecycle](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/qa/qa/specs/features/browser_ui), and so, if you are creating tests for issue creation, for instance, you would locate the spec files under the `qa/qa/specs/features/browser_ui/2_plan/` directory since issue creation is part of the Plan stage.

 In another case of a test for listing merged merge requests (MRs), the test should go under the `qa/qa/specs/features/browser_ui/3_create/` directory since merge request is a feature from the Create stage.

> There may be sub-directories inside the stages directories, for different features. For example: `.../browser_ui/2_plan/ee_epics/` and `.../browser_ui/2_plan/issues/`.

Now, let's say we want to create tests for the [scoped labels](https://about.gitlab.com/2019/04/22/gitlab-11-10-released/#scoped-labels) feature, available on GitLab EE Premium (this feature is part of the Plan stage.)

> Because these tests are for a feature available only on GitLab EE, we need to create them in the [EE repository](https://gitlab.com/gitlab-org/gitlab-ee).

Since [there is no specific directory for this feature](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/qa/qa/specs/features/browser_ui/2_plan), we should create a sub-directory for it.

Under `.../browser_ui/2_plan/`, let's create a sub-directory called `ee_scoped_labels/`.

> Notice that since this feature is only available for GitLab EE we prefix the sub-directory with `ee_`.

### 2. Test skeleton

Inside the newly created sub-directory, let's create a file describing the test suite (e.g. `editing_scoped_labels_spec.rb`.)

#### The `context` and `describe` blocks

Specs have an outer `context` that indicates the DevOps stage. The next level is the `describe` block, that briefly states the subject of the test suite. See the following example:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels properties on issues' do
    end
  end
end
```

#### The `it` blocks

Every test suite is composed by at least one `it` block, and a good way to start writing end-to-end tests is by typing test cases descriptions as `it` blocks. Take a look at the following example:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels properties on issues' do
      it 'replaces an existing label if it has the same key' do
      end

      it 'keeps both scoped labels when adding a label with a different key' do
      end
    end
  end
end
```

### 3. Test cases MVC

For the [MVC](https://about.gitlab.com/handbook/values/#minimum-viable-change-mvc) of our test cases, let's say that we already have the application in the state needed for the tests, and then let's focus on the logic of the test cases only.

To evolve the test cases drafted on step 2, let's imagine that the user is already logged in a GitLab EE instance, they already have at least a Premium license in use, there is already a project created, there is already an issue opened in the project, the issue already has a scoped label (e.g. `foo::bar`), there are other scoped labels (for the same scope and for a different scope, e.g. `foo::baz` and `bar::bah`), and finally, the user is already on the issue's page. Let's also suppose that for every test case the application is in a clean state, meaning that one test case won't affect another.

> Note: there are different approaches to create an application state for end-to-end tests. Some of them are very time consuming and subject to failures, such as when using the GUI for all the pre-conditions of the tests. On the other hand, other approaches are more efficient, such as using the public APIs. The latter is more efficient since it doesn't depend on the GUI. We won't focus on this part yet, but it's good to keep it in mind.

Let's now focus on the first test case.

```ruby
it 'keeps the latest scoped label when adding a label with the same key of an existing one, but with a different value' do
  # This implementation is only for tutorial purposes. We normally encapsulate elements in Page Objects.
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys ['foo::baz', :enter]
  page.find('#content-body').click
  page.refresh

  scoped_label = page.find('.qa-labels-block .scoped-label-wrapper')

  expect(scoped_label).to have_content('foo::baz')
  expect(scoped_label).not_to have_content('foo::bar')
  expect(page).to have_content('added foo::baz label and removed foo::bar')
end
```

> Notice that the test itself is simple. The most challenging part is the creation of the application state, which will be covered later.

> The exemplified test cases' MVC is not enough for the change to be submitted in an MR, but they help on building up the test logic. The reason is that we do not want to use locators directly in the tests, and tests **must** use [Page Objects](./qa/page/README.md) before they can be merged.

Below are the steps that the test covers:

1. The test finds the 'Edit' link for the labels and clicks on it
2. Then it fills in the 'Assign labels' input field with the value 'foo::baz' and press enter
3. Then it clicks in the content body to apply the label and refreshes the page
4. Finally the expectation that the previous scoped label was removed and that the new one was added happens

Let's now see how the second test case would look like.

```ruby
it 'keeps both scoped labels when adding a label with a different key' do
  # This implementation is only for tutorial purposes. We normally encapsulate elements in Page Objects.
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys ['bar::bah', :enter]
  page.find('#content-body').click
  page.refresh

  scoped_labels = page.all('.qa-labels-block .scoped-label-wrapper')

  expect(scoped_labels.first).to have_content('bar::bah')
  expect(scoped_labels.last).to have_content('foo::ba')
  expect(page).to have_content('added bar::bah')
  expect(page).to have_content('added foo::ba')
end
```

> Note that elements are always located using CSS selectors, and a good practice is to add test specific attribute:value for elements (this is called adding testability to the application and we will talk more about it later.)

Below are the steps that the test covers:

1. The test finds the 'Edit' link for the labels and clicks on it
2. Then it fills in the 'Assign labels' input field with the value 'bar::bah' and press enter
3. Then it clicks in the content body to apply the label and refreshes the page
4. Finally the expectation that the both scoped labels are present happens

> Similar to the previous test, this one is also very straight forward, but there is some code duplication. Let's address it.

### 4. Extracting duplicated code

If we refactor the tests created on step 3 we could come up with something like this:

```ruby
it 'keeps the latest scoped label when adding a label with the same key of an existing one, but with a different value' do
  select_label_and_refresh 'foo::baz'

  expect(page).to have_content('added foo::baz')
  expect(page).to have_content('and removed foo::bar')

  scoped_label = page.find('.qa-labels-block .scoped-label-wrapper')

  expect(scoped_label).to have_content('foo::baz')
  expect(scoped_label).not_to have_content('foo::bar')
end

it 'keeps both scoped label when adding a label with a different key' do
  select_label_and_refresh 'bar::bah'

  expect(page).to have_content('added bar::bah')
  expect(page).to have_content('added foo::ba')

  scoped_labels = page.all('.qa-labels-block .scoped-label-wrapper')

  expect(scoped_labels.first).to have_content('bar::bah')
  expect(scoped_labels.last).to have_content('foo::ba')
end

def select_label_and_refresh(label)
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys [label, :enter]
  page.find('#content-body').click
  page.refresh
end
```

By creating a reusable `select_label_and_refresh` method, we remove the code duplication, and later we can move this method to a Page Object class that will be created for easier maintenance purposes.

> Notice that the reusable method is created in the bottom of the file. The reason for that is that reading the code should be similar to reading a newspaper, where high-level information is at the top, like the title and summary of the news, while low level, or more specific information, is at the bottom.

### 5. Tests' pre-conditions using resources and Page Objects

In this section, we will address the previously mentioned subject of creating the application state for the tests, using the `before :all` and `before` blocks, together with resources and Page Objects.

#### `before :all`

A pre-condition for the entire test suite is defined in the `before :all` block.

For our test suite example, some things that could happen before the entire test suite starts are:

- The user logging in;
- A premium license already being set up;
- A project being created with an issue and labels already setup.

> In case of a test suite with only one `it` block it's ok to use only the `before` block (see below) with all the test's pre-conditions.

#### `before`

A pre-condition for each test case is defined in the `before` block.

For our test cases samples, what we need is that for every test the issue page is opened, and there is only one scoped label applied to it.

#### Implementation

In the following code we will focus on the test suite and the test cases' pre-conditions only:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels properties on issues' do
      before :all do
        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'scoped-labels-project'
        end

        @foo_bar_scoped_label = 'foo::bar'

        @issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.title = 'Issue to test the scoped labels'
          issue.labels = @foo_bar_scoped_label
        end

        @labels = ['foo::baz', 'bar::bah']
        @labels.each do |label|
          Resource::Label.fabricate_via_api! do |l|
            l.project = project.id
            l.title = label
          end
        end

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      before do
        Page::Project::Issue::Show.perform do |issue_page|
          @issue.visit!
        end
      end

      it 'keeps the latest scoped label when adding a label with the same key of an existing one, but with a different value' do
        ...
      end

      it 'keeps both scoped labels when adding a label with a different key' do
        ...
      end

      def select_label_and_refresh(label)
        ...
      end
    end
  end
end
```

In the `before :all` block we create all the application state needed for the tests to run. We do that by fabricating resources via APIs (`project`, `@issue`, and `@labels`), by using the `Runtime::Browser.visit` method to go to the login page, and by performing a `sign_in_using_credentials` from the `Login` Page Object.

> When creating the resources, notice that when calling the `fabricate_via_api` method, we pass some attribute:values, like `name` for the `project` resource; `project`, `title`, and `labels` for the `issue` resource; and `project`, and `title` for `label` resources.

> What's important to understand here is that by creating the application state mostly using the public APIs we save a lot of time in the test suite setup stage.

> Soon we will cover the use of the already existing resources' methods and the creation of your own `fabricate_via_api` methods for resources where this is still not available, but first, let's optimize our implementation.

### 6. Optimization

As already mentioned in the [best practices](./BEST_PRACTICES.md) document, end-to-end tests are very costly in terms of execution time, and it's our responsibility as software engineers to ensure that we optimize them as much as possible.

> Differently than unit tests, that exercise every little piece of the application in isolation, usually having only one assertion per test, and being very fast to run, end-to-end tests can have more actions and assertions in a single test to help on speeding up the test's feedback since they are much slower when comparing to unit tests.

Some improvements that we could make in our test suite to optimize its time to run are:

1. Having a single test case (an `it` block) that exercise both scenarios to avoid "wasting" time in the tests' pre-conditions, instead of having two different test cases.
2. Moving all the pre-conditions to the `before` block since there will be only one `it` block.
3. Making the selection of labels more performant by allowing for the selection of more than one label in the same reusable method.

Let's look at a suggestion that addresses the above points, one by one:

```ruby
module QA
    context 'Plan' do
      describe 'Editing scoped labels properties on issues' do
        before do
          project = Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'scoped-labels-project'
          end

          @foo_bar_scoped_label = 'foo::bar'

          @issue = Resource::Issue.fabricate_via_api! do |issue|
            issue.project = project
            issue.title = 'Issue to test the scoped labels'
            issue.labels = @foo_bar_scoped_label
          end

          @labels = ['foo::baz', 'bar::bah']
          @labels.each do |label|
            Resource::Label.fabricate_via_api! do |l|
              l.project = project.id
              l.title = label
            end
          end

          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_credentials)
          Page::Project::Issue::Show.perform do |issue_page|
            @issue.visit!
          end
        end

        it 'correctly applies the scoped labels depending if they are from the same or a different scope' do
          select_labels_and_refresh @labels

          scoped_labels = page.all('.qa-labels-block .scoped-label-wrapper')

          expect(page).to have_content("added #{@foo_bar_scoped_label}")
          expect(page).to have_content("added #{@labels[1]} #{@labels[0]} labels and removed #{@foo_bar_scoped_label}")
          expect(scoped_labels.count).to eq(2)
          expect(scoped_labels.first).to have_content(@labels[1])
          expect(scoped_labels.last).to have_content(@labels[0])
        end

        def select_labels_and_refresh(labels)
          find('.block.labels .edit-link').click
          labels.each do |label|
            find('.dropdown-menu-labels .dropdown-input-field').send_keys [label, :enter]
          end
          find('#content-body').click
          refresh
        end
      end
    end
  end
```

As you can see, now all the pre-conditions from the `before :all` block were moved to the `before` block, addressing point 2.

To address point 1, we changed the test implementation from two `it` blocks into a single one that exercises both scenarios. Now the new test description is: `'correctly applies the scoped labels depending if they are from the same or a different scope'`. It's a long description, but it describes well what the test does.

> Notice that the implementation of the new and unique `it` block had to change a little bit. Below we describe in details what it does.

1. At the same time, it selects two scoped labels, one from the same scope of the one already applied in the issue during the setup phase (in the `before` block), and another one from a different scope.
2. It runs the assertions that the labels where correctly added and removed; that only two labels are applied; and that those are the correct ones, and that they are shown in the right order.

Finally, the `select_label_and_refresh` method is changed to `select_labels_and_refresh`, which accepts an array of labels instead of a single label, and it iterates on them for faster label selection (this is what is used in step 1 explained above.)

### 7. Resources

You can think of resources as anything that can be created on GitLab CE or EE, either through the GUI, the API, or the CLI.

With that in mind, resources can be a project, an epic, an issue, a label, a commit, etc.

As you saw in the tests' pre-conditions and the optimization sections, we're already creating some of these resources, and we are doing that by calling the `fabricate_via_api!` method.

> We could be using the `fabricate!` method instead, which would use the `fabricate_via_api!` method if it exists, and fallback to GUI fabrication otherwise, but we recommend being explicit to make it clear what the test does. Also, we recommend fabricating resources via API since this makes tests faster and more reliable, unless the test is focusing on the GUI itself, or there's no GUI coverage for that specific part in any other test.

For our test suite example, the [project resource](https://gitlab.com/gitlab-org/gitlab-ee/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/project.rb#L55) already had a `fabricate_via_api!` method available, while other resources don't have it, so we will have to create them, like for the issue and label resources. Also, we will have to make a small change in the project resource to expose its `id` attribute so that we can refer to it when fabricating the issue.

#### Implementation

Following we describe the changes needed in every of the before-mentioned resource files.

**Project resource**

Let's start with the smallest change.

In the [project resource](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/project.rb), let's expose its `id` attribute.

Add the following `attribute :id` right below the [`attribute :description`](https://gitlab.com/gitlab-org/gitlab-ee/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/project.rb#L11).

> This line is needed to allow for issues and labels to be automatically added to a project when fabricating them via API.

**Issue resource**

Now, let's make it possible to create an issue resource through the API.

First, in the [issue resource](https://gitlab.com/gitlab-org/gitlab-ee/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb), let's expose its labels attribute.

Add the following `attribute :labels` right below the [`attribute :title`](https://gitlab.com/gitlab-org/gitlab-ee/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb#L15).

> This line is needed to allow for labels to be automatically added to an issue when fabricating it via API.

Next, add the following code right below the [`fabricate!`](https://gitlab.com/gitlab-org/gitlab-ee/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb#L27) method.

```ruby
def api_get_path
  "/projects/#{project.id}/issues/#{id}"
end

def api_post_path
  "/projects/#{project.id}/issues"
end

def api_post_body
  {
    title: title,
    labels: [labels]
  }
end
```

By defining the `api_get_path` method, we allow the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to get a single issue.

> This `GET` path can be found in the [public API documentation](https://docs.gitlab.com/ee/api/issues.html#single-issue).

By defining the `api_post_path` method, we allow the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to create a new issue in a specific project.

> This `POST` path can be found in the [public API documentation](https://docs.gitlab.com/ee/api/issues.html#new-issue).

By defining the `api_post_body` method, we allow the [`ApiFabricator.api_post`](https://gitlab.com/gitlab-org/gitlab-ee/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/api_fabricator.rb#L68) method to know which data to send when making the `POST` request.

> Notice that we pass both `title` and `labels` attributes in the `api_post_body`, where `labels` receives an array of labels, and [`title` is required](https://docs.gitlab.com/ee/api/issues.html#new-issue).

**Label resource**

Finally, let's make it possible to create label resources through the API.

Add the following code right below the [`fabricate!`](https://gitlab.com/gitlab-org/gitlab-ee/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/label.rb#L36) method.

```ruby
def resource_web_url(resource)
  super
rescue ResourceURLMissingError
  # this particular resource does not expose a web_url property
end

def api_get_path
  raise NotImplementedError, "The Labels API doesn't expose a single-resource endpoint so this method cannot be properly implemented."
end

def api_post_path
  "/projects/#{project}/labels"
end

def api_post_body
  {
    name: @title,
    color: @color
  }
end
```

By defining the `resource_web_url(resource)` method, we override the one from the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/api_fabricator.rb#L44) module. We do that to avoid failing the test due to this particular resource not exposing a `web_url` property.

By defining the `api_get_path` method, we **would** allow for the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to get a single label, but since there's no path available for that in the publich API, we raise a `NotImplementedError` instead.

By defining the `api_post_path` method, we allow for the [`ApiFabricator `](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to create a new label in a specific project.

By defining the `api_post_body` method, we we allow for the [`ApiFabricator.api_post`](https://gitlab.com/gitlab-org/gitlab-ee/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/api_fabricator.rb#L68) method to know which data to send when making the `POST` request.

> Notice that we pass both `name` and `color` attributes in the `api_post_body` since [those are required](https://docs.gitlab.com/ee/api/labels.html#create-a-new-label).

### 8. Page Objects

> Page Objects are auto-loaded in the `qa/qa.rb` file and available in all the  test files (`*_spec.rb`).

Page Objects are used in end-to-end tests for maintenance reasons, where page's elements and methods are defined to be reused in any test.

Take a look at [this document that specifically details the usage of Page Objects](./qa/page/README.md).

Now, let's go back to our examples.

...

#### Adding testability

TBD.
