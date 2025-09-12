// Given Markdown text, clean up pipe tables and apply proper formatting,
// aligning pipes in proper columns.
// Empty string is returned if there is a problem formatting a table.

// For detecting/extracting a table row
const ROW_REGEXP = /^(\s*)(\|(.+?\|)+)\s*$/;

// For detecting/extracting a table header separator row
const HEADER_SEPARATOR_REGEXP = /^:?-+:?$/;

// Parse table cells from a row, handling empty cells between consecutive pipes
function parseCells(row) {
  return row
    .replace(/\|\s*/g, '| ')
    .trim()
    .split('|')
    .map((cell) => cell.trim())
    .slice(1, -1);
}

// Check if all cells in a row represent a header separator
function isHeaderSeparator(cells) {
  return cells.length > 0 && cells.every((cell) => HEADER_SEPARATOR_REGEXP.test(cell));
}

// Determine column alignment from header cell syntax
function getAlignment(cell) {
  if (cell.startsWith(':') && cell.endsWith(':')) return 'center';
  if (cell.endsWith(':')) return 'right';
  return 'left';
}

// Calculate optimal column widths
function calculateColumnWidths(table) {
  if (!table.length) return [];

  const widths = new Array(table[0].length).fill(0);
  for (const row of table) {
    for (let i = 0; i < row.length; i += 1) {
      if (widths[i] === undefined) widths.push(0);
      widths[i] = Math.max(widths[i], row[i].length);
    }
  }
  return widths;
}

// Align text within specified width
function alignText(text, align, width) {
  const padding = width - text.length;
  if (padding <= 0) return text;

  switch (align) {
    case 'right':
      return `${' '.repeat(padding)}${text}`;
    case 'center': {
      const leftPad = Math.floor(padding / 2);
      return `${' '.repeat(leftPad)}${text}${' '.repeat(padding - leftPad)}`;
    }
    default: // 'left'
      return `${text}${' '.repeat(padding)}`;
  }
}

// Build formatted table row
function buildRow(cells, { widths, alignments, indent = 0 }) {
  const prefix = `${' '.repeat(indent)}|`;
  const formattedCells = cells
    .map((cell, i) => ` ${alignText(cell, alignments[i] || 'left', widths[i])} `)
    .join('|');
  return `${prefix}${formattedCells}|\n`;
}

// Build header separator row
function buildHeaderSeparator({ alignments, widths, indent = 0 }) {
  const prefix = `${' '.repeat(indent)}|`;
  const separators = alignments
    .map((align, i) => {
      const width = widths[i];
      let sep = '';

      if (align === 'center') sep += ':';

      let dashPadding = 2; // default for 'left'
      if (align === 'right') dashPadding = 1;
      if (align === 'center') dashPadding = 0;

      sep += '-'.repeat(width + dashPadding);
      if (align === 'right' || align === 'center') sep += ':';

      return sep;
    })
    .join('|');
  return `${prefix}${separators}|\n`;
}

// Insert an empty row if we found a header separator without a preceding content row
function adjustRows(rows, alignments, headerRowIndex) {
  if (headerRowIndex === 0 && rows.length > 0) {
    // Use the number of alignment entries to determine column count
    rows.unshift(new Array(alignments.length).fill(''));
  }
}

// Format complete table
function formatTable(rows, alignments, indent = 0) {
  if (!rows.length) return '';

  const widths = calculateColumnWidths(rows);
  let result = '';

  // Ensure alignments array has correct length
  if (alignments.length < widths.length) {
    for (let i = alignments.length; i < widths.length; i += 1) {
      alignments.push('left');
    }
  }

  // Pad rows with fewer columns than the maximum width
  for (let i = 0; i < rows.length; i += 1) {
    if (rows[i].length < widths.length) {
      for (let j = rows[i].length; j < widths.length; j += 1) {
        rows[i].push('');
      }
    }
  }

  // First data row (or empty row if header was first)
  result += buildRow(rows[0], { widths, alignments, indent });

  // Header separator
  result += buildHeaderSeparator({ alignments, widths, indent });

  // Remaining rows
  for (let i = 1; i < rows.length; i += 1) {
    result += buildRow(rows[i], { widths, alignments, indent });
  }

  return result;
}

export function formatMarkdownTable(text) {
  if (!text) return '';

  const lines = text.split(/\r?\n/);
  let result = '';
  let currentTable = null;

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const match = line.match(ROW_REGEXP);

    if (match) {
      const indent = match[1].length;
      const cells = parseCells(match[2]);

      if (!currentTable) {
        currentTable = {
          rows: [],
          alignments: null,
          indent,
          headerRowIndex: -1,
        };
      }

      if (isHeaderSeparator(cells)) {
        currentTable.alignments = cells.map((cell) => getAlignment(cell));
        currentTable.headerRowIndex = currentTable.rows.length;
      } else {
        currentTable.rows.push(cells);
      }
    } else {
      // Non-table line encountered
      if (currentTable) {
        if (currentTable.alignments) {
          // Complete the current table
          const { rows, alignments, indent, headerRowIndex } = currentTable;

          adjustRows(rows, alignments, headerRowIndex);
          result += formatTable(rows, alignments, indent);
        } else {
          return '';
        }
      }

      currentTable = null;
      result += `${line}\n`;
    }
  }

  // Handle table at end of text
  if (currentTable && currentTable.alignments) {
    const { rows, alignments, indent, headerRowIndex } = currentTable;

    adjustRows(rows, alignments, headerRowIndex);
    result += formatTable(rows, alignments, indent);
  }

  // Remove trailing newline if it exists
  return result.endsWith('\n') ? result.substring(0, result.length - 1) : result;
}
