import { tableCellAsTaskTableItem } from '~/content_editor/services/serialization_helpers';
import { builders } from '../serialization_utils';

const { paragraph, tableCell, taskList, taskItem } = builders;

describe('tableCellAsTaskTableItem', () => {
  it('returns null when cell has multiple children', () => {
    const cell = tableCell(taskList(taskItem(paragraph())), paragraph());

    expect(tableCellAsTaskTableItem(cell)).toBeNull();
  });

  it('returns null when the only child is not a taskList', () => {
    const cell = tableCell(paragraph());

    expect(tableCellAsTaskTableItem(cell)).toBeNull();
  });

  it('returns the task item when it contains only an empty paragraph', () => {
    const cell = tableCell(taskList(taskItem(paragraph())));

    expect(tableCellAsTaskTableItem(cell)).toBe(cell.child(0).child(0));
  });

  it('returns null when the task item has non-empty content', () => {
    const cell = tableCell(taskList(taskItem(paragraph('some text'))));

    expect(tableCellAsTaskTableItem(cell)).toBeNull();
  });

  it('returns null when the task item has multiple children', () => {
    const cell = tableCell(taskList(taskItem(paragraph(), paragraph())));

    expect(tableCellAsTaskTableItem(cell)).toBeNull();
  });
});
