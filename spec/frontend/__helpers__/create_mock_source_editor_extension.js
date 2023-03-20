export const createMockSourceEditorExtension = (ActualExtension) => {
  const { extensionName } = ActualExtension;
  const providedKeys = Object.keys(new ActualExtension().provides());

  const mockedMethods = Object.fromEntries(providedKeys.map((key) => [key, jest.fn()]));
  const MockExtension = function MockExtension() {};
  MockExtension.extensionName = extensionName;
  MockExtension.mockedMethods = mockedMethods;
  MockExtension.prototype.provides = jest.fn().mockReturnValue(mockedMethods);

  return MockExtension;
};
