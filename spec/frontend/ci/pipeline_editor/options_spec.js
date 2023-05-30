import { createAppOptions } from '~/ci/pipeline_editor/options';
import { editorDatasetOptions, expectedInjectValues } from './mock_data';

describe('createAppOptions', () => {
  let el;

  const createElement = () => {
    el = document.createElement('div');

    document.body.appendChild(el);
    Object.entries(editorDatasetOptions).forEach(([k, v]) => {
      el.dataset[k] = v;
    });
  };

  afterEach(() => {
    el = null;
  });

  it("extracts the properties from the element's dataset", () => {
    createElement();
    const options = createAppOptions(el);
    Object.entries(expectedInjectValues).forEach(([key, value]) => {
      expect(options.provide).toMatchObject({ [key]: value });
    });
  });
});
