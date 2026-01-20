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
  const getDiffElement = () => document.querySelector('[data-diff-element]');
  const getChangesButton = () => document.querySelector('button[data-click="showChanges"]');
  const getRichViewButton = () => document.querySelector('button[data-click="toggleRichView"]');
  const getShowFullFileButton = () => document.querySelector('button[data-click="showFullFile"]');
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
      <${name} data-file-data='${JSON.stringify({ viewer, old_path: 'foo', new_path: 'bar' })}'>
        <div data-diff-element>
          ${content}
        </div>
      </${name}>
    `;

  const mount = ({ rendered = false, full = false } = {}) => {
    setHTMLFixture(
      createComponentHtml(
        'diff-file',
        `
          <button data-click="showChanges">button</button>
          <button data-click="showFullFile" ${full ? 'data-full="true"' : ''}>Show full file</button>
          <button data-click="toggleRichView" data-rendered="${JSON.stringify(rendered)}">button</button>
        `,
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
    delegatedClick(getChangesButton());
    expect(getChangesButton().disabled).toBe(true);
    await waitForPromises();
    expect(getExpandedContent()).not.toBeFalsy();
  });

  it.each([true, false])('loads file with plain_view %s', async (rendered) => {
    mockAdapter
      .onGet(`${getRequestUrl()}&plain_view=${rendered}`)
      .reply(
        HTTP_STATUS_OK,
        createComponentHtml(
          'new-diff-file',
          '<div id="expanded">Expanded Content<button></button></div>',
        ),
      );
    mount({ rendered });
    delegatedClick(getRichViewButton());
    expect(getRichViewButton().disabled).toBe(true);
    await waitForPromises();
    expect(getExpandedContent()).not.toBeFalsy();
  });

  it.each([true, false])('loads file with full set to %s', async (full) => {
    mockAdapter
      .onGet(`${getRequestUrl()}&full=${!full}`)
      .reply(
        HTTP_STATUS_OK,
        createComponentHtml(
          'new-diff-file',
          '<div id="expanded">Expanded Content<button></button></div>',
        ),
      );
    mount({ full });
    delegatedClick(getShowFullFileButton());
    expect(getShowFullFileButton().disabled).toBe(true);
    await waitForPromises();
    expect(getExpandedContent()).not.toBeFalsy();
  });

  it('handles error', async () => {
    mockAdapter.onGet(getRequestUrl()).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    mount();
    delegatedClick(getChangesButton());
    expect(getChangesButton().disabled).toBe(true);
    await waitForPromises();
    expect(getChangesButton().disabled).toBe(false);
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Failed to load changes, please try again.',
      parent: getDiffElement(),
      error: expect.any(Object),
    });
  });
});
