export const renderGlql = async (els = []) => {
  if (els.length === 0) return;
  const { default: render } = await import(/* webpackChunkName: 'glql' */ '~/glql');
  render(els);
};
