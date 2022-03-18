import { Document, parseDocument } from 'yaml';
import { isValidStepSeq } from '~/pipeline_wizard/validators';
import { steps as stepsYaml } from './mock/yaml';

describe('prop validation', () => {
  const steps = parseDocument(stepsYaml).toJS();
  const getAsYamlNode = (value) => new Document(value).contents;

  it('allows passing yaml nodes to the steps prop', () => {
    const validSteps = getAsYamlNode(steps);
    expect(isValidStepSeq(validSteps)).toBe(true);
  });

  it.each`
    scenario                     | stepsValue
    ${'not a seq'}               | ${{ foo: 'bar' }}
    ${'a step missing an input'} | ${[{ template: 'baz: boo' }]}
    ${'an empty seq'}            | ${[]}
  `('throws an error when passing $scenario to the steps prop', ({ stepsValue }) => {
    expect(isValidStepSeq(stepsValue)).toBe(false);
  });
});
