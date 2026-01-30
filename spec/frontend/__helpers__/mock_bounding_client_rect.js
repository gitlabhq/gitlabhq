export const useMockBoundingClientRect = (
  value = {
    width: 24,
    height: 24,
    top: 0,
    left: 0,
    bottom: 0,
    right: 0,
  },
) => {
  beforeEach(() => {
    jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue(value);
  });
};
