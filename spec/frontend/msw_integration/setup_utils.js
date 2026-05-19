export async function setupRouter(router) {
  const { path } = router.currentRoute;
  const { base } = router.history;
  if (path && path !== base && path !== `/${base}`) {
    await router.push(base);
  }
}
