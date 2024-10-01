describe('dompurify dependency', () => {
  it('should not be updated unless mermaid is verified', () => {
    // why: We use `require` so that we don't have to manually dig through node_modules
    // eslint-disable-next-line global-require
    const { version } = require('dompurify/package.json');

    // NOTE: Bumping this to 3.1.7 breaks mermaid diagrams. When upgrading DOMPurify, you **must** manually verify that
    //       mermaid diagrams work visually before fixing this test. For more context:
    //       - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167644
    //       - https://github.com/cure53/DOMPurify/issues/1002#issuecomment-2381258197
    expect(version).toEqual('3.1.6');
  });
});
