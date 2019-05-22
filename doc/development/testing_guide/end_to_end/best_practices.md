# Best practices when writing end-to-end tests

The majority of the end-to-end tests require some state to be built in the application for the tests to happen.

A good example is a user being logged in as a pre-condition for testing the feature.

But if the login feature is already covered with end-to-end tests through the GUI, there is no reason to perform such an expensive task to test the functionality of creating a project, or importing a repo, even if these features depend on a user being logged in. Let's see an example to make things clear.

Let's say that, on average, the process to perform a successful login through the GUI takes 2 seconds.

Now, realize that almost all tests need the user to be logged in, and that we need every test to run in isolation, meaning that tests cannot interfere with each other. This would  mean that for every test the user needs to log in, and "waste 2 seconds".

Now, multiply the number of tests per 2 seconds, and as your test suite grows, the time to run it grows with it, and this is not sustainable.

An alternative to perform a login in a cheaper way would be having an endpoint (available only for testing) where we could pass the user's credentials as encrypted values as query strings, and then we would be redirected to the logged in home page if the credentials are valid. Let's say that, on average, this process takes only 200 miliseconds.

You see the point right?

Performing a login through the GUI for every test would cost a lot in terms of tests' execution.

And there is another reason.

Let's say that you don't follow the above suggestion, and depend on the GUI for the creation of every application state in order to test a specific feature. In this case we could be talking about the **Issues** feature, that depends on a project to exist, and the user to be logged in.

What would happen if there was a bug in the project creation page, where the 'Create' button is disabled, not allowing for the creation of a project through the GUI, but the API logic is still working?

In this case, instead of having only the project creation test failing, we would have many tests that depend on a project to be failing too.

But, if we were following the best practices, only one test would be failing, and tests for other features that depend on a project to exist would continue to pass, since they could be creating the project behind the scenes interacting directly with the public APIs, ensuring a more reliable metric of test failure rate.

Finally, interacting with the application only by its GUI generates a higher rate of test flakiness, and we want to avoid that at max.

**The takeaways here are:**

- Building state through the GUI is time consuming and it's not sustainable as the test suite grows.
- When depending only on the GUI to create the application's state and tests fail due to front-end issues, we can't rely on the test failures rate, and we generate a higher rate of test flakiness.

Now that we are aware of all of it, [let's go create some tests](quick_start_guide.md).
