const Sortablejs = jest.createMockFromModule('sortablejs');

Sortablejs.create = jest.fn(() => ({ destroy: () => {}, option: () => {} }));

export default Sortablejs;
export const Sortable = Sortablejs;
export class MultiDrag {}
