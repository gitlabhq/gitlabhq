#!/bin/bash
for i in `ls *html.haml`;do echo $i;cp $i ${i/.html.haml/.zh.html.haml};done
vim -p *zh*