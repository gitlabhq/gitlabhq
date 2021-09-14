export const logHelloDeferred = async () => {
  const { logHello } = await import(/* webpackChunkName: 'hello' */ './hello');

  logHello();
};
