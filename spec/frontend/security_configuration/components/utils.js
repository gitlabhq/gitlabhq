export const makeFeature = (changes = {}) => ({
  name: 'Foo Feature',
  description: 'Lorem ipsum Foo',
  type: 'foo_scanning',
  helpPath: '/help/foo',
  configurationHelpPath: '/help/foo#configure',
  ...changes,
});
