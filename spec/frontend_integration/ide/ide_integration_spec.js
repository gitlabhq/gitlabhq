/**
 * WARNING: WIP
 *
 * Please do not copy from this spec or use it as an example for anything.
 *
 * This is in place to iteratively set up the frontend integration testing environment
 * and will be improved upon in a later iteration.
 *
 * See https://gitlab.com/gitlab-org/gitlab/-/issues/208800 for more information.
 */
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { initIde } from '~/ide';

jest.mock('~/api', () => {
  return {
    project: jest.fn().mockImplementation(() => new Promise(() => {})),
  };
});

jest.mock('~/ide/services/gql', () => {
  return {
    query: jest.fn().mockImplementation(() => new Promise(() => {})),
  };
});

describe('WebIDE', () => {
  let vm;
  let root;
  let mock;
  let initData;
  let location;

  beforeEach(() => {
    root = document.createElement('div');
    initData = {
      emptyStateSvgPath: '/test/empty_state.svg',
      noChangesStateSvgPath: '/test/no_changes_state.svg',
      committedStateSvgPath: '/test/committed_state.svg',
      pipelinesEmptyStateSvgPath: '/test/pipelines_empty_state.svg',
      promotionSvgPath: '/test/promotion.svg',
      ciHelpPagePath: '/test/ci_help_page',
      webIDEHelpPagePath: '/test/web_ide_help_page',
      clientsidePreviewEnabled: 'true',
      renderWhitespaceInCode: 'false',
      codesandboxBundlerUrl: 'test/codesandbox_bundler',
    };

    mock = new MockAdapter(axios);
    mock.onAny('*').reply(() => new Promise(() => {}));

    location = { pathname: '/-/ide/project/gitlab-test/test', search: '', hash: '' };
    Object.defineProperty(window, 'location', {
      get() {
        return location;
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;

    mock.restore();
  });

  const createComponent = () => {
    const el = document.createElement('div');
    Object.assign(el.dataset, initData);
    root.appendChild(el);
    vm = initIde(el);
  };

  expect.addSnapshotSerializer({
    test(value) {
      return value instanceof HTMLElement && !value.$_hit;
    },
    print(element, serialize) {
      element.$_hit = true;
      element.querySelectorAll('[style]').forEach(el => {
        el.$_hit = true;
        if (el.style.display === 'none') {
          el.textContent = '(jest: contents hidden)';
        }
      });

      return serialize(element)
        .replace(/^\s*<!---->$/gm, '')
        .replace(/\n\s*\n/gm, '\n');
    },
  });

  it('runs', () => {
    createComponent();

    return vm.$nextTick().then(() => {
      expect(root).toMatchSnapshot();
    });
  });
});
