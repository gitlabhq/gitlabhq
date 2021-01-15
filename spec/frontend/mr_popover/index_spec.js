import { setHTMLFixture } from 'helpers/fixtures';
import * as createDefaultClient from '~/lib/graphql';
import initMRPopovers from '~/mr_popover/index';

createDefaultClient.default = jest.fn();

describe('initMRPopovers', () => {
  let mr1;
  let mr2;
  let mr3;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="one" class="gfm-merge_request" data-mr-title="title" data-iid="1" data-project-path="group/project">
        MR1
      </div>
      <div id="two" class="gfm-merge_request" data-mr-title="title" data-iid="1" data-project-path="group/project">
        MR2
      </div>
      <div id="three" class="gfm-merge_request">
        MR3
      </div>
    `);

    mr1 = document.querySelector('#one');
    mr2 = document.querySelector('#two');
    mr3 = document.querySelector('#three');

    mr1.addEventListener = jest.fn();
    mr2.addEventListener = jest.fn();
    mr3.addEventListener = jest.fn();
  });

  it('does not add the same event listener twice', () => {
    initMRPopovers([mr1, mr1, mr2]);

    expect(mr1.addEventListener).toHaveBeenCalledTimes(1);
    expect(mr2.addEventListener).toHaveBeenCalledTimes(1);
  });

  it('does not add listener if it does not have the necessary data attributes', () => {
    initMRPopovers([mr1, mr2, mr3]);

    expect(mr3.addEventListener).not.toHaveBeenCalled();
  });
});
