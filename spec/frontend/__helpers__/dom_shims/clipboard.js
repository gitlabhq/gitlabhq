Object.defineProperty(navigator, 'clipboard', {
  value: {
    writeText: () => {},
  },
});
