# Writing end-to-end tests step-by-step

In this tutorial, you will find different examples, and the steps involved, in the creation of end-to-end (_e2e_) tests for GitLab CE and GitLab EE, using GitLab QA.

> When referring to end-to-end tests in this document, this means testing a specific feature end-to-end, such as a user logging in, the creation of a project, the management of labels, breaking down epics into sub-epics and issues, etc.

## Important information before we start writing tests

It's important to understand that end-to-end tests of isolated features, such as the ones described in the above note, doesn't mean that everything needs to happen through the GUI.

If you don't exactly understand what we mean by **not everything needs to happen through the GUI,** please make sure you've read the [best practices](best_practices.md) before moving on.

## This document covers the following items

- [0.](#0-are-end-to-end-tests-needed) Identifying if end-to-end tests are really needed
- [1.](#1-identifying-the-devops-stage) Identifying the [DevOps stage](https://about.gitlab.com/stages-devops-lifecycle/) of the feature that you are going to cover with end-to-end tests
- [2.](#2-test-skeleton) Creating the skeleton of the test file (`*_spec.rb`)
- [3.](#3-test-cases-mvc) The [MVC](https://about.gitlab.com/handbook/values/#minimum-viable-change-mvc) of the test cases' logic
- [4.](#4-extracting-duplicated-code) Extracting duplicated code into methods
- [5.](#5-tests-pre-conditions-using-resources-and-page-objects) Tests' pre-conditions (`before :context` and `before`) using resources and [Page Objects]
- [6.](#6-optimization) Optimizing the test suite
- [7.](#7-resources) Using and implementing resources
- [8.](#8-page-objects) Moving element definitions and methods to [Page Objects]

### 0. Are end-to-end tests needed?

At GitLab we respect the [test pyramid](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/testing_guide/testing_levels.md), and so, we recommend you check the code coverage of a specific feature before writing end-to-end tests, for both [CE](https://gitlab-org.gitlab.io/gitlab-foss/coverage-ruby/#_AllFiles) and [EE](https://gitlab-org.gitlab.io/gitlab/coverage-ruby/#_AllFiles) projects.

Sometimes you may notice that there is already good coverage in lower test levels, and we can stay confident that if we break a feature, we will still have quick feedback about it, even without having end-to-end tests.

> For analyzing the code coverage, you will also need to understand which application files implement specific functionalities.

#### Some other guidelines are as follows

- Take a look at the [How to test at the correct level?](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/testing_guide/testing_levels.md#how-to-test-at-the-correct-level) section of the [Testing levels](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/testing_guide/testing_levels.md) document

- Look into the frequency in which such a feature is changed  (_Stable features that don't change very often might not be worth covering with end-to-end tests if they're already covered in lower levels_)

- Finally, discuss with the developer(s) involved in developing the feature and the tests themselves, to get their feeling

If after this analysis you still think that end-to-end tests are needed, keep reading.

### 1. Identifying the DevOps stage

The GitLab QA end-to-end tests are organized by the different [stages in the DevOps lifecycle](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/qa/qa/specs/features/browser_ui), and so, if you are creating tests for issue creation, for instance, you would locate the spec files under the `qa/qa/specs/features/browser_ui/2_plan/` directory since issue creation is part of the Plan stage.

 In another case of a test for listing merged merge requests (MRs), the test should go under the `qa/qa/specs/features/browser_ui/3_create/` directory since merge requests are a feature from the Create stage.

> There may be sub-directories inside the stages directories, for different features. For example: `.../browser_ui/2_plan/ee_epics/` and `.../browser_ui/2_plan/issues/`.

Now, let's say we want to create tests for the [scoped labels](https://about.gitlab.com/blog/2019/04/22/gitlab-11-10-released/#scoped-labels) feature, available on GitLab EE Premium (this feature is part of the Plan stage.)

> Because these tests are for a feature available only on GitLab EE, we need to create them in the [EE repository](https://gitlab.com/gitlab-org/gitlab).

Since [there is no specific directory for this feature](https://gitlab.com/gitlab-org/gitlab/tree/master/qa/qa/specs/features/browser_ui/2_plan), we should create a sub-directory for it.

Under `.../browser_ui/2_plan/`, let's create a sub-directory called `ee_scoped_labels/`.

> Notice that since this feature is only available for GitLab EE we prefix the sub-directory with `ee_`.

### 2. Test skeleton

Inside the newly created sub-directory, let's create a file describing the test suite (e.g. `editing_scoped_labels_spec.rb`.)

#### The `context` and `describe` blocks

Specs have an outer `context` that indicates the DevOps stage. The next level is the `describe` block, that briefly states the subject of the test suite. See the following example:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
    end
  end
end
```

#### The `it` blocks

Every test suite is composed of at least one `it` block, and a good way to start writing end-to-end tests is by writing test cases descriptions as `it` blocks. These might help you to think of different test scenarios. Take a look at the following example:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
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

To evolve the test cases drafted on step 2, let's imagine that the user is already logged into a GitLab EE instance, they already have at least a Premium license in use, there is already a project created, there is already an issue opened in the project, the issue already has a scoped label (e.g. `animal::fox`), there are other scoped labels (for the same scope and for a different scope (e.g. `animal::dolphin` and `plant::orchid`), and finally, the user is already on the issue's page. Let's also suppose that for every test case the application is in a clean state, meaning that one test case won't affect another.

> Note: there are different approaches to creating an application state for end-to-end tests. Some of them are very time consuming and subject to failures, such as when using the GUI for all the pre-conditions of the tests. On the other hand, other approaches are more efficient, such as using the public APIs. The latter is more efficient since it doesn't depend on the GUI. We won't focus on this part yet, but it's good to keep it in mind.

Let's now focus on the first test case.

```ruby
it 'replaces an existing label if it has the same key' do
  # This implementation is only for tutorial purposes. We normally encapsulate elements in Page Objects (which we cover on section 8).
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys ['animal::dolphin', :enter]
  page.find('#content-body').click
  page.refresh

  labels_block = page.find(%q([data-qa-selector="labels_block"]))

  expect(labels_block).to have_content('animal::dolphin')
  expect(labels_block).not_to have_content('animal::fox')
  expect(page).to have_content('added animal::dolphin label and removed animal::fox')
end
```

> Notice that the test itself is simple. The most challenging part is the creation of the application state, which will be covered later.
>
> The exemplified test case's MVC is not enough for the change to be merged, but it helps to build up the test logic. The reason is that we do not want to use locators directly in the tests, and tests **must** use [Page Objects] before they can be merged. This way we better separate the responsibilities, where the Page Objects encapsulate elements and methods that allow us to interact with pages, while the spec files describe the test cases in more business-related language.

Below are the steps that the test covers:

1. The test finds the 'Edit' link for the labels and clicks on it.
1. Then it fills in the 'Assign labels' input field with the value 'animal::dolphin' and press enters.
1. Then it clicks in the content body to apply the label and refreshes the page.
1. Finally, the expectations check that the previous scoped label was removed and that the new one was added.

Let's now see how the second test case would look.

```ruby
it 'keeps both scoped labels when adding a label with a different key' do
  # This implementation is only for tutorial purposes. We normally encapsulate elements in Page Objects (which we cover on section 8).
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys ['plant::orchid', :enter]
  page.find('#content-body').click
  page.refresh

  labels_block = page.find(%q([data-qa-selector="labels_block"]))

  expect(labels_block).to have_content('animal::fox')
  expect(labels_block).to have_content('plant::orchid')
  expect(page).to have_content('added animal::fox')
  expect(page).to have_content('added plant::orchid')
end
```

> Note that elements are always located using CSS selectors, and a good practice is to add test-specific selectors (this is called "testability"). For example, the `labels_block` element uses the CSS selector [`data-qa-selector="labels_block"`](page_objects.md#data-qa-selector-vs-qa-selector), which was added specifically for testing purposes.

Below are the steps that the test covers:

1. The test finds the 'Edit' link for the labels and clicks on it.
1. Then it fills in the 'Assign labels' input field with the value 'plant::orchid' and press enters.
1. Then it clicks in the content body to apply the label and refreshes the page.
1. Finally, the expectations check that both scoped labels are present.

> Similar to the previous test, this one is also very straightforward, but there is some code duplication. Let's address it.

### 4. Extracting duplicated code

If we refactor the tests created on step 3 we could come up with something like this:

```ruby
before do
  ...

  @initial_label = 'animal::fox'
  @new_label_same_scope = 'animal::dolphin'
  @new_label_different_scope = 'plant::orchid'

  ...
end

it 'replaces an existing label if it has the same key' do
  select_label_and_refresh @new_label_same_scope

  labels_block = page.find(%q([data-qa-selector="labels_block"]))

  expect(labels_block).to have_content(@new_label_same_scope)
  expect(labels_block).not_to have_content(@initial_label)
  expect(page).to have_content("added #{@new_label_same_scope}")
  expect(page).to have_content("and removed #{@initial_label}")
end

it 'keeps both scoped label when adding a label with a different key' do
  select_label_and_refresh @new_label_different_scope

  labels_block = page.find(%q([data-qa-selector="labels_block"]))

  expect(labels_blocks).to have_content(@new_label_different_scope)
  expect(labels_blocks).to have_content(@initial_label)
  expect(page).to have_content("added #{@new_label_different_scope}")
  expect(page).to have_content("added #{@initial_label}")
end

def select_label_and_refresh(label)
  page.find('.block.labels .edit-link').click
  page.find('.dropdown-menu-labels .dropdown-input-field').send_keys [label, :enter]
  page.find('#content-body').click
  page.refresh
end
```

First, we remove the duplication of strings by defining the global variables `@initial_label`, `@new_label_same_scope` and `@new_label_different_scope` in the `before` block, and by using them in the expectations.

Then, by creating a reusable `select_label_and_refresh` method, we remove the code duplication of this action, and later we can move this method to a Page Object class that will be created for easier maintenance purposes.

> Notice that the reusable method is created at the bottom of the file. The reason for that is that reading the code should be similar to reading a newspaper, where high-level information is at the top, like the title and summary of the news, while low level, or more specific information, is at the bottom (this helps readability).

### 5. Tests' pre-conditions using resources and Page Objects

In this section, we will address the previously mentioned subject of creating the application state for the tests, using the `before :context` and `before` blocks, together with resources and Page Objects.

#### `before :context`

A pre-condition for the entire test suite is defined in the `before :context` block.

> For our test suite, due to the need of the tests being completely independent of each other, we won't use the `before :context` block. The `before :context` block would make the tests dependent on each other because the first test changes the label of the issue, and the second one depends on the `'animal::fox'` label being set.

TIP: **Tip:** In case of a test suite with only one `it` block it's ok to use only the `before` block (see below) with all the test's pre-conditions.

#### `before`

As the pre-conditions for our test suite, the things that needs to happen before each test starts are:

- The user logging in;
- A premium license already being set;
- A project being created with an issue and labels already set;
- The issue page being opened with only one scoped label applied to it.

> When running end-to-end tests as part of the GitLab's continuous integration process [a license is already set as an environment variable](https://gitlab.com/gitlab-org/gitlab/blob/1a60d926740db10e3b5724713285780a4f470531/qa/qa/ee/strategy.rb#L20). For running tests locally you can set up such license by following the document [what tests can be run?](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md), based on the [supported GitLab environment variables](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#supported-gitlab-environment-variables).

#### Implementation

In the following code we will focus only on the test suite's pre-conditions:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        @initial_label = 'animal::fox'
        @new_label_same_scope = 'animal::dolphin'
        @new_label_different_scope = 'plant::orchid'

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue to test the scoped labels'
          issue.labels = [@initial_label]
        end

        [@new_label_same_scope, @new_label_different_scope].each do |label|
          Resource::Label.fabricate_via_api! do |l|
            l.project = issue.project
            l.title = label
          end
        end

        issue.visit!
      end

      it 'replaces an existing label if it has the same key' do
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

In the `before` block we create all the application state needed for the tests to run. We do that by using the `Runtime::Browser.visit` method to go to the login page, by performing a `sign_in_using_credentials` from the `Login` Page Object, by fabricating resources via APIs (`issue`, and `Resource::Label`), and by using the `issue.visit!` to visit the issue page.

> A project is created in the background by creating the `issue` resource.
>
> When creating the [Resources], notice that when calling the `fabricate_via_api` method, we pass some attribute:values, like `title`, and `labels` for the `issue` resource; and `project` and `title` for the `label` resource.
>
> What's important to understand here is that by creating the application state mostly using the public APIs we save a lot of time in the test suite setup stage.
>
> Soon we will cover the use of the already existing resources' methods and the creation of your own `fabricate_via_api` methods for resources where this is still not available, but first, let's optimize our implementation.

### 6. Optimization

As already mentioned in the [best practices](best_practices.md) document, end-to-end tests are very costly in terms of execution time, and it's our responsibility as software engineers to ensure that we optimize them as much as possible.

> Note that end-to-end tests are slow to run and so they can have several actions and assertions in a single test, which helps us get feedback from the tests sooner. In comparison, unit tests are much faster to run and can exercise every little piece of the application in isolation, and so they usually have only one assertion per test.

Some improvements that we could make in our test suite to optimize its time to run are:

1. Having a single test case (an `it` block) that exercises both scenarios to avoid "wasting" time in the tests' pre-conditions, instead of having two different test cases.
1. Making the selection of labels more performant by allowing for the selection of more than one label in the same reusable method.

Let's look at a suggestion that addresses the above points, one by one:

```ruby
module QA
    context 'Plan' do
      describe 'Editing scoped labels on issues' do
        before do
          ...
        end

        it 'correctly applies scoped labels depending on if they are from the same or a different scope' do
          select_labels_and_refresh [@new_label_same_scope, @new_label_different_scope]

          labels_block = page.all(%q([data-qa-selector="labels_block"]))

          expect(labels_block).to have_content(@new_label_same_scope)
          expect(labels_block).to have_content(@new_label_different_scope)
          expect(labels_block).not_to have_content(@initial_label)
          expect(page).to have_content("added #{@initial_label}")
          expect(page).to have_content("added #{@new_label_same_scope} #{@new_label_different_scope} labels and removed #{@initial_label}")
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

To address point 1, we changed the test implementation from two `it` blocks into a single one that exercises both scenarios. Now the new test description is: `'correctly applies the scoped labels depending if they are from the same or a different scope'`. It's a long description, but it describes well what the test does.

> Notice that the implementation of the new and unique `it` block had to change a little bit. Below we describe in details what it does.

1. It selects two scoped labels simultaneously, one from the same scope of the one already applied in the issue during the setup phase (in the `before` block), and another one from a different scope.
1. It asserts that the correct labels are visible in the `labels_block`, and that the labels were correctly added and removed;
1. Finally, the `select_label_and_refresh` method is changed to `select_labels_and_refresh`, which accepts an array of labels instead of a single label, and it iterates on them for faster label selection (this is what is used in step 1 explained above.)

### 7. Resources

**Note:** When writing this document, some code that is now merged to master was not implemented yet, but we left them here for the readers to understand the whole process of end-to-end test creation.

You can think of [Resources] as anything that can be created on GitLab CE or EE, either through the GUI, the API, or the CLI.

With that in mind, resources can be a project, an epic, an issue, a label, a commit, etc.

As you saw in the tests' pre-conditions and the optimization sections, we're already creating some of these resources, and we are doing that by calling the `fabricate_via_api!` method.

> We could be using the `fabricate!` method instead, which would use the `fabricate_via_api!` method if it exists, and fallback to GUI fabrication otherwise, but we recommend being explicit to make it clear what the test does. Also, we always recommend fabricating resources via API since this makes tests faster and more reliable.

For our test suite example, the resources that we need to create don't have the necessary code for the `fabricate_via_api!` method to correctly work (e.g., the issue and label resources), so we will have to create them.

#### Implementation

In the following we describe the changes needed in each of the resource files mentioned above.

**Issue resource**

Now, let's make it possible to create an issue resource through the API.

First, in the [issue resource](https://gitlab.com/gitlab-org/gitlab/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb), let's expose its id and labels attributes.

Add the following `attribute :id` and `attribute :labels` right above the [`attribute :title`](https://gitlab.com/gitlab-org/gitlab/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb#L15).

> This line is needed to allow for the issue fabrication, and for labels to be automatically added to the issue when fabricating it via API.
>
> We add the attributes above the existing attribute to keep them alphabetically organized.

Then, let's initialize an instance variable for labels to allow an empty array as default value when such information is not passed during the resource fabrication, since this optional. [Between the attributes and the `fabricate!` method](https://gitlab.com/gitlab-org/gitlab/blob/1a1f1408728f19b2aa15887cd20bddab7e70c8bd/qa/qa/resource/issue.rb#L18), add the following:

```ruby
def initialize
  @labels = []
end
```

Next, add the following code right below the [`fabricate!`](https://gitlab.com/gitlab-org/gitlab/blob/d3584e80b4236acdf393d815d604801573af72cc/qa/qa/resource/issue.rb#L27) method.

```ruby
def api_get_path
  "/projects/#{project.id}/issues/#{id}"
end

def api_post_path
  "/projects/#{project.id}/issues"
end

def api_post_body
  {
    labels: labels,
    title: title
  }
end
```

By defining the `api_get_path` method, we allow the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to get a single issue.

> This `GET` path can be found in the [public API documentation](../../../api/issues.md#single-issue).

By defining the `api_post_path` method, we allow the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to create a new issue in a specific project.

> This `POST` path can be found in the [public API documentation](../../../api/issues.md#new-issue).

By defining the `api_post_body` method, we allow the [`ApiFabricator.api_post`](https://gitlab.com/gitlab-org/gitlab/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/api_fabricator.rb#L68) method to know which data to send when making the `POST` request.

> Notice that we pass both `labels` and `title` attributes in the `api_post_body`, where `labels` receives an array of labels, and [`title` is required](../../../api/issues.md#new-issue). Also, notice that we keep them alphabetically organized.

**Label resource**

Finally, let's make it possible to create label resources through the API.

Add the following code right below the [`fabricate!`](https://gitlab.com/gitlab-org/gitlab/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/label.rb#L36) method.

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
  "/projects/#{project.id}/labels"
end

def api_post_body
  {
    color: @color,
    name: @title
  }
end
```

By defining the `resource_web_url(resource)` method, we override the one from the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/resource/api_fabricator.rb#L44) module. We do that to avoid failing the test due to this particular resource not exposing a `web_url` property.

By defining the `api_get_path` method, we **would** allow for the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to get a single label, but since there's no path available for that in the publich API, we raise a `NotImplementedError` instead.

By defining the `api_post_path` method, we allow for the [`ApiFabricator`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/resource/api_fabricator.rb) module to know which path to use to create a new label in a specific project.

By defining the `api_post_body` method, we we allow for the [`ApiFabricator.api_post`](https://gitlab.com/gitlab-org/gitlab/blob/a9177ca1812bac57e2b2fa4560e1d5dd8ffac38b/qa/qa/resource/api_fabricator.rb#L68) method to know which data to send when making the `POST` request.

> Notice that we pass both `color` and `name` attributes in the `api_post_body` since [those are required](../../../api/labels.md#create-a-new-label). Also, notice that we keep them alphabetically organized.

### 8. Page Objects

Page Objects are used in end-to-end tests for maintenance reasons, where a page's elements and methods are defined to be reused in any test.

> Page Objects are auto-loaded in the [`qa/qa.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa.rb) file and available in all the test files (`*_spec.rb`).

Take a look at the [Page Objects] documentation.

Now, let's go back to our example.

As you may have noticed, we are defining elements with CSS selectors and the `select_labels_and_refresh` method directly in the test file, and this is an anti-pattern since we need to better separate the responsibilities.

To address this issue, we will move the implementation to Page Objects, and the test suite will only focus on the business rules that we are testing.

#### Updates in the test file

As in a test-driven development approach, let's start changing the test file even before the Page Object implementation is in place.

Replace the code of the `it` block in the test file by the following:

```ruby
module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
      before do
        ...
      end

      it 'correctly applies scoped labels depending on if they are from the same or a different scope' do
        Page::Project::Issue::Show.perform do |issue_page|
          issue_page.select_labels_and_refresh [@new_label_same_scope, @new_label_different_scope]

          expect(page).to have_content("added #{@initial_label}")
          expect(page).to have_content("added #{@new_label_same_scope} #{@new_label_different_scope} labels and removed #{@initial_label}")
          expect(issue_page.text_of_labels_block).to have_content(@new_label_same_scope)
          expect(issue_page.text_of_labels_block).to have_content(@new_label_different_scope)
          expect(issue_page.text_of_labels_block).not_to have_content(@initial_label)
        end
      end
    end
  end
end
```

Notice that `select_labels_and_refresh` is now a method from the issue Page Object (which is not yet implemented), and that we verify the labels' text by using `text_of_labels_block`, instead of via the `labels_block` element. The `text_of_labels_block` method will also be implemented in the issue Page Object.

Let's now update the Issue Page Object.

#### Updates in the Issue Page Object

> Page Objects are located in the `qa/qa/page/` directory, and its sub-directories.

The file we will have to change is the [Issue Page Object](https://gitlab.com/gitlab-org/gitlab/blob/master/qa/qa/page/project/issue/show.rb).

First, add the following code right below the definition of an already implemented view (keep in mind that view's definitions and their elements should be alphabetically ordered):

```ruby
view 'app/helpers/dropdowns_helper.rb' do
  element :dropdown_input_field
end

view 'app/views/shared/issuable/_sidebar.html.haml' do
  element :dropdown_menu_labels
  element :edit_link_labels
  element :labels_block
end
```

Similarly to what we did before, let's first change the Page Object even without the elements being defined in the view (`_sidebar.html.haml`) and the `dropdowns_helper.rb` files, and later we will update them by adding the appropriate CSS selectors.

Now, let's implement the methods `select_labels_and_refresh` and `text_of_labels_block`.

Somewhere between the definition of the views and the private methods, add the following snippet of code (these should also be alphabetically ordered for organization reasons):

```ruby
def select_labels_and_refresh(labels)
  click_element(:edit_link_labels)
  labels.each do |label|
    within_element(:dropdown_menu_labels, text: label) do
      send_keys_to_element(:dropdown_input_field, [label, :enter])
    end
  end
  click_body
  labels.each do |label|
    has_element?(:labels_block, text: label)
  end
  refresh
end

def text_of_labels_block
  find_element(:labels_block)
end
```

##### Details of `select_labels_and_refresh`

Notice that we have not only moved the `select_labels_and_refresh` method, but we have also changed its implementation to:

1. Click the `:edit_link_labels` element previously defined, instead of using `find('.block.labels .edit-link').click`
1. Use `within_element(:dropdown_menu_labels, text: label)`, and inside of it, we call `send_keys_to_element(:dropdown_input_field, [label, :enter])`, which is a method that we will implement in the `QA::Page::Base` class to replace `find('.dropdown-menu-labels .dropdown-input-field').send_keys [label, :enter]`
1. Use `click_body` after iterating on each label, instead of using `find('#content-body').click`
1. Iterate on every label again, and then we use `has_element?(:labels_block, text: label)` after clicking the page body (which applies the labels), and before refreshing the page, to avoid test flakiness due to refreshing too fast.

##### Details of `text_of_labels_block`

The `text_of_labels_block` method is a simple method that returns the `:labels_block` element (`find_element(:labels_block)`).

#### Updates in the view (*.html.haml) and `dropdowns_helper.rb` files

Now let's change the view and the `dropdowns_helper` files to add the selectors that relate to the [Page Objects].

In  [`app/views/shared/issuable/_sidebar.html.haml:105`](https://gitlab.com/gitlab-org/gitlab/blob/7ca12defc7a965987b162a6ebef302f95dc8867f/app/views/shared/issuable/_sidebar.html.haml#L105), add a `data: { qa_selector: 'edit_link_labels' }` data attribute.

The code should look like this:

```haml
= link_to _('Edit'), '#', class: 'js-sidebar-dropdown-toggle edit-link float-right', data: { qa_selector: 'edit_link_labels' }
```

In the same file, on [line 121](https://gitlab.com/gitlab-org/gitlab/blob/7ca12defc7a965987b162a6ebef302f95dc8867f/app/views/shared/issuable/_sidebar.html.haml#L121), add a `data: { qa_selector: 'dropdown_menu_labels' }` data attribute.

The code should look like this:

```haml
.dropdown-menu.dropdown-select.dropdown-menu-paging.dropdown-menu-labels.dropdown-menu-selectable.dropdown-extended-height{ data: { qa_selector: 'dropdown_menu_labels' } }
```

In [`app/helpers/dropdowns_helper.rb:94`](https://gitlab.com/gitlab-org/gitlab/blob/7ca12defc7a965987b162a6ebef302f95dc8867f/app/helpers/dropdowns_helper.rb#L94), add a `data: { qa_selector: 'dropdown_input_field' }` data attribute.

The code should look like this:

```ruby
filter_output = search_field_tag search_id, nil, class: "dropdown-input-field", placeholder: placeholder, autocomplete: 'off', data: { qa_selector: 'dropdown_input_field' }
```

> `data-qa-*` data attributes and CSS classes starting with `qa-` are used solely for the purpose of QA and testing.
> By defining these, we add **testability** to the application.
>
> When defining a data attribute like: `qa_selector: 'labels_block'`, it should match the element definition: `element :labels_block`. We use a [sanity test](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/development/testing_guide/end_to_end/page_objects.md#how-did-we-solve-fragile-tests-problem) to check that defined elements have their respective selectors in the specified views.

#### Updates in the `QA::Page::Base` class

The last thing that we have to do is to update `QA::Page::Base` class to add the `send_keys_to_element` method on it.

Add the following snippet of code somewhere where class methods are defined (remember to organize methods alphabetically, and if you see a place where this standard is not being followed, it would be helpful if you could rearrange it):

```ruby
def send_keys_to_element(name, keys)
  find_element(name).send_keys(keys)
end
```

This method receives an element (`name`) and the `keys` that it will send to that element, and the keys are an array that can receive strings, or "special" keys, like `:enter`.

As you might remember, in the Issue Page Object we call this method like this: `send_keys_to_element(:dropdown_input_field, [label, :enter])`.

With that, you should be able to start writing end-to-end tests yourself. *Congratulations!*

[Page Objects]: page_objects.md
[Resources]: resources.md
