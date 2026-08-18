import { initPipelineEditor } from '~/ci/pipeline_editor';
import * as optionsCE from '~/ci/pipeline_editor/options';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

jest.mock('~/lib/utils/vue3compat/init_vue_app', () => ({
  initVueApp: jest.fn().mockReturnValue({ app: true }),
}));

describe('initPipelineEditor', () => {
  let el;
  const selector = 'SELECTOR';

  beforeEach(() => {
    jest.spyOn(optionsCE, 'createAppOptions').mockReturnValue({ option: 2 });

    el = document.createElement('div');
    el.id = selector;
    document.body.appendChild(el);
  });

  afterEach(() => {
    document.body.removeChild(el);
  });

  it('returns null if there are no elements found', () => {
    expect(initPipelineEditor()).toBeNull();
  });

  it('bootstraps the app with the created options and returns it', () => {
    expect(initPipelineEditor(`#${selector}`)).toEqual({ app: true });
    expect(initVueApp).toHaveBeenCalledWith({ option: 2 });
  });
});
