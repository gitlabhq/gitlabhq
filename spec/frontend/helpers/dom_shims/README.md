## Jest DOM shims

This is where we shim parts of JSDom. It is imported in our root `test_setup.js`.

### Why do we need this?

Since JSDom mocks a real DOM environment (which is a good thing), it 
unfortunately does not support some jQuery matchers. 

### References

- https://gitlab.com/gitlab-org/gitlab/merge_requests/17906#note_224448120
