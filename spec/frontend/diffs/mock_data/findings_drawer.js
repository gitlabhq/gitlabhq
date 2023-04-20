export default {
  line: 7,
  description:
    "Unused method argument - `c`. If it's necessary, use `_` or `_c` as an argument name to indicate that it won't be used.",
  severity: 'minor',
  engineName: 'testengine name',
  categories: ['testcategory 1', 'testcategory 2'],
  content: {
    body: 'Duplicated Code Duplicated code',
  },
  location: {
    path: 'workhorse/config_test.go',
    lines: { begin: 221, end: 284 },
  },
  otherLocations: [
    { path: 'testpath', href: 'http://testlink.com' },
    { path: 'testpath 1', href: 'http://testlink.com' },
    { path: 'testpath2', href: 'http://testlink.com' },
  ],
  type: 'issue',
};
