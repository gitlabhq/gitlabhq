import { initPipelineEditor } from '~/ci/pipeline_editor';
import * as optionsCE from '~/ci/pipeline_editor/options';

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

  it('returns an object if there is an element found', () => {
    expect(initPipelineEditor(`#${selector}`)).toMatchObject({});
  });
});
