Object.defineProperty(navigator, 'clipboard', {
  value: {
    read: () => Promise.resolve([]),
    writeText: () => {},
  },
});
