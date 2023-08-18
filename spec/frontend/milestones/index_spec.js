import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initShow, MILESTONE_DESCRIPTION_ELEMENT } from '~/milestones/index';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/milestones/milestone');
jest.mock('~/right_sidebar');
jest.mock('~/sidebar/mount_milestone_sidebar');
jest.mock('~/lib/graphql');

describe('#initShow', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="detail-page-description milestone-detail">
        <div class="description">
          <div class="markdown-code-block">
            <pre class="js-render-mermaid">
              graph TD;
                A-- > B;
                A-- > C;
                B-- > D;
                C-- > D;
            </pre>
          </div>
        </div>
      </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('calls `renderGFM` to ensure that all gitlab-flavoured markdown is rendered on the milestone details page', () => {
    initShow();

    expect(renderGFM).toHaveBeenCalledWith(document.querySelector(MILESTONE_DESCRIPTION_ELEMENT));
  });
});
