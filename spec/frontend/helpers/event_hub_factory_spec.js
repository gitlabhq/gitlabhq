import createEventHub from '~/helpers/event_hub_factory';
import mitt from 'mitt';

jest.mock('mitt');

mitt.mockReturnValue({
  on: () => {},
  off: () => {},
  emit: () => {},
});

describe('event bus factory', () => {
  let eventBus;

  beforeEach(() => {
    eventBus = createEventHub();
  });

  afterEach(() => {
    eventBus = null;
  });

  it('creates an emitter', () => {
    expect(mitt).toHaveBeenCalled();
  });

  it.each`
    method
    ${'on'}
    ${'off'}
    ${'emit'}
  `('binds $$method to $method ', ({ method }) => {
    expect(typeof eventBus[method]).toBe('function');
    expect(eventBus[method]).toBe(eventBus[`$${method}`]);
  });
});
