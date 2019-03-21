describe('dummy test', () => {
  it('waits for a loooooong time', () => {
    setTimeout(() => {
      throw new Error('broken');
    }, 10000);
  });
});
