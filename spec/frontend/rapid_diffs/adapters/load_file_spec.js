import MockAxiosAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { setHTMLFixture } from 'helpers/fixtures';
import { loadFileAdapter } from '~/rapid_diffs/adapters/load_file';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEST_HOST } from 'spec/test_constants';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { pinia } from '~/pinia/instance';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('loadFileAdapter', () => {
  const viewer = 'any';
  const diffFileEndpoint = '/diff-file';

  let mockAdapter;

  const getDiffFile = () => document.querySelector('diff-file');
  const getButton = () => document.querySelector('button[data-click="showChanges"]');
  const getExpandedContent = () => document.querySelector('#expanded');
  const getRequestUrl = () =>
    `${TEST_HOST}${diffFileEndpoint}?old_path=foo&new_path=bar&ignore_whitespace_changes=${!useDiffsView(pinia).showWhitespace}`;

  const mountComponent = (component = getDiffFile()) => {
    component.mount({
      adapterConfig: { [viewer]: [loadFileAdapter] },
      appData: { diffFileEndpoint },
      unobserve: jest.fn(),
    });
  };

  const createComponentHtml = (name, content) => `
      <${name} data-file-data='${JSON.stringify({ viewer })}'>
        ${content}
      </${name}>
    `;

  const mount = () => {
    setHTMLFixture(
      createComponentHtml(
        'diff-file',
        `<button data-click="showChanges" data-paths='${JSON.stringify({ old_path: 'foo', new_path: 'bar' })}'>button</button>`,
      ),
    );
    mountComponent();
  };

  const delegatedClick = (element) => {
    let event;
    element.addEventListener(
      'click',
      (e) => {
        event = e;
      },
      { once: true },
    );
    element.click();
    getDiffFile().onClick(event);
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
    customElements.define(
      'new-diff-file',
      class extends DiffFile {
        constructor(...args) {
          super(...args);
          mountComponent(this);
        }
      },
    );
  });

  beforeEach(() => {
    mockAdapter = new MockAxiosAdapter(axios);
  });

  it.each([true, false])('expands file with hide whitespace %s', async (whitespace) => {
    useDiffsView(pinia).showWhitespace = whitespace;
    mockAdapter
      .onGet(getRequestUrl())
      .reply(
        HTTP_STATUS_OK,
        createComponentHtml(
          'new-diff-file',
          '<div id="expanded">Expanded Content<button></button></div>',
        ),
      );
    mount();
    delegatedClick(getButton());
    expect(getButton().disabled).toBe(true);
    await waitForPromises();
    expect(getExpandedContent()).not.toBeFalsy();
  });

  it('handles error', async () => {
    mockAdapter.onGet(getRequestUrl()).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    mount();
    delegatedClick(getButton());
    expect(getButton().disabled).toBe(true);
    await waitForPromises();
    expect(getButton().disabled).toBe(false);
    expect(createAlert).toHaveBeenCalled();
  });
});
