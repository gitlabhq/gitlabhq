import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { setupRootElement } from '~/ide/lib/gitlab_web_ide/setup_root_element';

describe('~/ide/lib/gitlab_web_ide/setup_root_element', () => {
  beforeEach(() => {
    setHTMLFixture(`
    <div id="ide-test-root" class="js-not-a-real-class">
      <span>We are loading lots of stuff...</span>
    </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findIDERoot = () => document.getElementById('ide-test-root');

  it('has no children, has original ID, and classes', () => {
    const result = setupRootElement(findIDERoot());

    // why: Assert that the return element matches the new one found in the dom
    //      (implying a el.replaceWith...)
    expect(result).toBe(findIDERoot());
    expect(result).toMatchInlineSnapshot(`
      <div
        class="gl-flex gl-h-full gl-items-center gl-justify-center gl-relative"
        id="reference-0"
      />
    `);
  });
});
