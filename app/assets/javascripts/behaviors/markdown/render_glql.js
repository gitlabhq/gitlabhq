export const renderGlql = async (els) => {
  const { default: render } = await import(/* webpackChunkName: 'glql' */ '~/glql');
  return render(els);
};
