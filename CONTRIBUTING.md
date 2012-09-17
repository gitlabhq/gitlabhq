## Contribute to Gitlab 

If you want to contribute to Gitlab, follow this process:

1. Fork the project
2. Create a feature branch
3. Code
4. Create a pull request

We only accept pull requests if: 

* Your code has proper tests and all tests pass
* Your code can be merged w/o problems 
* It wont broke existing functionality
* Its a quality code
* We like it :)

## [You may need a developer VM](https://github.com/gitlabhq/developer-vm)

## Running tests

To run the specs for Gitlab, you need to run seeds for test db.

    cd gitlabhq
    rake db:seed_fu RAILS_ENV=test

Then you can run the test suite with rake:

    rake gitlab:test

