---
stage: enablement
group: Tenant Scale
description: 'Cells: Diagrams'
---

# Diagrams

Diagrams used in Cells are created with [draw.io](https://draw.io).

## Edit existing diagrams

Load the `.drawio.png` or `.drawio.svg` file directly into **draw.io**, which you can use in several ways:

- Best: Use the [draw.io integration in VSCode](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio).
- Good: Install on MacOS with `brew install drawio` or download the [draw.io desktop](https://github.com/jgraph/drawio-desktop/releases).
- Good: Install on Linux by downloading the [draw.io desktop](https://github.com/jgraph/drawio-desktop/releases).
- Discouraged: Use the [draw.io website](https://draw.io) to load and save files.

## Create a diagram

To create a diagram from a file:

1. Copy existing file and rename it. Ensure that the extension is `.drawio.png` or `.drawio.svg`.
1. Edit the diagram.
1. Save the file.
1. Optimize images with `pngquant -f --ext .png *.drawio.png` to reduce their size by 2-3x.

To create a diagram from scratch using [draw.io desktop](https://github.com/jgraph/drawio-desktop/releases):

1. In **File > New > Create new diagram**, select **Blank diagram**.
1. In **File > Save As**, select **Editable Bitmap .png**, and save with `.drawio.png` extension.
1. To improve image quality, in **File > Properties**, set **Zoom** to **200%**.
1. To save the file with the new zoom setting, select **File > Save**.
1. Optimize images with `pngquant -f --ext .png *.drawio.png` to reduce their size by 2-3x.

DO NOT use the **File > Export** function. The diagram should be embedded into `.png` for easy editing.
